import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FRModule/mytodolist.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:unosfa/pages/driver_map_view.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class OSMRouteTracking extends StatefulWidget {
  final String leadId;
  const OSMRouteTracking({super.key, required this.leadId});

  @override
  _OSMRouteTrackingState createState() => _OSMRouteTrackingState();
}

class _OSMRouteTrackingState extends State<OSMRouteTracking> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(0.0, 0.0);
  LatLng _destination = LatLng(0.0, 0.0);
  List<LatLng> _routePoints = [];
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    fetchLeadDetails();
    _fetchCurrentLocation();
  }

  bool isLoading = true;
  Map<String, dynamic> leadDetails = {};
  Future<void> fetchLeadDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/api/leads/${widget.leadId}/'), // Using leadId in the API URL
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        // Parse the response body as JSON
        setState(() {
          leadDetails = json.decode(response.body);
          isLoading = false; // Data loaded
          getLatLngFromAddress(
              leadDetails['address1'] + leadDetails['address2']);
        });
      } else if (response.statusCode == 401) {
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse(
              '${AppConfig.baseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
          body: mappedData,
        );
        final data = json.decode(response2.body);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        fetchLeadDetails();
      } else {
        throw Exception('Failed to load lead details');
      }
    } catch (e) {
      print('Error fetching lead details: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _destination =
              LatLng(locations.first.latitude, locations.first.longitude);
        });

        // Call route fetching function
        _fetchRoute(_destination);
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _fetchCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    await Future.delayed(Duration(seconds: 2));
    LatLng newPosition = LatLng(position.latitude, position.longitude);

    _updateCurrentPosition(newPosition);
  }

  void _updateCurrentPosition(LatLng newPosition) {
    setState(() {
      _currentPosition = newPosition;
    });
    _mapController.move(newPosition, 8.5);
  }

  Future<void> _fetchRoute(LatLng destination) async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng newPosition = LatLng(position.latitude, position.longitude);

    final routeUrl = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/${newPosition.longitude},${newPosition.latitude};${destination.longitude},${destination.latitude}?geometries=geojson");

    try {
      final response = await http.get(routeUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coordinates =
            data['routes'][0]['geometry']['coordinates'];

        List<LatLng> routePoints = coordinates
            .map((point) =>
                LatLng(point[1], point[0])) // Convert [lon, lat] to [lat, lon]
            .toList();

        setState(() {
          _routePoints = routePoints;
          _currentPosition = newPosition;
          _destination = destination;
        });
      } else {
        print("Failed to fetch route: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref("Lead Movement");
  StreamSubscription<Position>? _positionStream;
  bool isTracking = false;
  List<Map<String, dynamic>> path = []; // Stores all locations

  void startTracking() async {
    List<String>? userInfo;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => userInfo = prefs.getStringList('userInfo'));
    }
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      return;
    }

    // Start tracking
    setState(() => isTracking = true);
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (isTracking) {
        // Create a new location entry
        Map<String, dynamic> newLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Add new location to the path list
        path.add(newLocation);
        String unm = userInfo?.isNotEmpty == true ? userInfo![0] : "UnknownUser";

        // Store the full path in Firebase
        _dbRef.child(unm).set(path);
      }
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    setState(() => isTracking = false);
    print("Tracking Stopped");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFc433e0),
                Color(0xFF9a37ae),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/logo.PNG',
                  height: 30,
                ),
                SizedBox(width: 50),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyTodoList(searchQuery: ''),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentPosition, // This will be non-null
                zoom: 15,
                onMapReady: () {
                  _mapController.move(_currentPosition, 15.0);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.red, // Change color for visibility
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: _currentPosition,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.blue
                                  .withOpacity(0.3), // Circle background
                              shape: BoxShape.circle,
                            ),
                          ),
                          Icon(Icons.circle, color: Colors.blue, size: 20),
                        ],
                      ),
                    ),
                    Marker(
                      width: 30.0,
                      height: 30.0,
                      point: _destination,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lead Details:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Name: ${leadDetails['first_name']} ${leadDetails['middle_name']} ${leadDetails['last_name']}",
                    style: TextStyle(fontSize: 16, color: Color(0xFF2C2B2B)),
                  ),
                  Text(
                    "Phone Number: +${leadDetails['phone_number']} ",
                    style: TextStyle(fontSize: 16, color: Color(0xFF2C2B2B)),
                  ),
                  Text(
                    "Zip: ${leadDetails['zip']} ",
                    style: TextStyle(fontSize: 16, color: Color(0xFF2C2B2B)),
                  ),
                  Text(
                    "Location: ${leadDetails['location']} ",
                    style: TextStyle(fontSize: 16, color: Color(0xFF2C2B2B)),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                  Text(
                    "Destination:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Address: ${leadDetails['address1']} ${leadDetails['address2']}",
                    style: TextStyle(fontSize: 16, color: Color(0xFF2C2B2B)),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.02,
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: isTracking ? stopTracking : startTracking,
                          child: Text(
                              isTracking ? "Stop Tracking" : "Going For Lead"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.02,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          // child: Text(
                          //   "Going For Lead",
                          //   style: WidgetSupport.LoginButtonTextColor(),
                          // ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
