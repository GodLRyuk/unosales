import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FRModule/mytodolist.dart';
import 'package:http/http.dart' as http;
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class OSMRouteTracking extends StatefulWidget {
  final String leadId;
  const OSMRouteTracking({super.key, required this.leadId});

  @override
  _OSMRouteTrackingState createState() => _OSMRouteTrackingState();
}

class _OSMRouteTrackingState extends State<OSMRouteTracking> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(22.5726, 88.3639);
  bool _isTracking = false;
  List<LatLng> _routePoints = [];
  
  @override
  void initState() {
    super.initState();
    fetchLeadDetails();
    _getCurrentLocation();
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
            'http://167.88.160.87/api/leads/${widget.leadId}/'), // Using leadId in the API URL
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        // Parse the response body as JSON
        setState(() {
          leadDetails = json.decode(response.body);
          isLoading = false; // Data loaded
        });
      } else if (response.statusCode == 401) {
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse(
              'http://167.88.160.87/api/users/token-refresh/'), // Using leadId in the API URL
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

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _fetchRoute();
  }

  void _fetchRoute() {
    setState(() {
      _routePoints = [
        _currentPosition,
        LatLng((22.581041577139537 + _currentPosition.latitude) / 2,
            (88.43708952431639 + _currentPosition.longitude) / 2),
            
      ];
    });
    _mapController.move(_currentPosition, 14.0);
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
    });

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (_isTracking) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentPosition, 16.0);
      }
    });
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
                        builder: (context) => MyTodoList(
                              searchQuery: '',
                            )));
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
                center: _currentPosition,
                zoom: 14,
                onTap: (_, __) {},
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
                      color: Colors.red,
                      strokeWidth: 5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 30.0,
                      height: 30.0,
                      point: _currentPosition,
                      child: const Icon(Icons.directions_walk,
                          color: Colors.blue, size: 40),
                    ),
                    // Marker(
                    //   width: 30.0,
                    //   height: 30.0,
                    //   point: widget.destination,
                    //   child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    // ),
                  ],
                ),
                CurrentLocationLayer(),
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
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    "Phone Number: ${leadDetails['phone_number']} ",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    "Zip: ${leadDetails['zip']} ",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    "Location: ${leadDetails['location']} ",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    "Destination:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Address: ${leadDetails['address1']} ${leadDetails['address2']}",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.02,
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _startTracking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).orientation ==
                                      Orientation.portrait
                                  ? (MediaQuery.of(context).size.width < 600
                                      ? MediaQuery.of(context).size.width *
                                          0.00 // For phones in portrait
                                      : MediaQuery.of(context).size.width *
                                          0.03) // For tablets in portrait
                                  : (MediaQuery.of(context).size.width < 600
                                      ? MediaQuery.of(context).size.width *
                                          0.03 // For phones in landscape
                                      : MediaQuery.of(context).size.width *
                                          0.02), // For tablets in landscape
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text(
                            "Going For Lead",
                            style: WidgetSupport.LoginButtonTextColor(),
                          ),
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
