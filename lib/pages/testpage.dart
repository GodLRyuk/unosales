import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
import 'dart:convert';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:url_launcher/url_launcher.dart';

const String graphHopperApiKey = "2fba5594-bcb7-4dde-b7e3-10939e376981";

class MapNavigationPage extends StatefulWidget {
  @override
  _MapNavigationPageState createState() => _MapNavigationPageState();
}

class _MapNavigationPageState extends State<MapNavigationPage> {
  late MapController _mapController;
  LatLng _currentPosition = LatLng(0.0, 0.0);
  LatLng _destination = LatLng(0.0, 0.0);
  List<LatLng> _routePoints = [];
  double lat = 00.00;
  double Long = 00.00;
  bool _isSpeechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    getCurrentLocation();
    fetchLeadDetails();
    trackUserMovement();
  }

  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPosition;
      });

      // Move the map to the new position
      _mapController.move(_currentPosition, 15.0);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void trackUserMovement() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentPosition, 15.0);
    });
  }



  void processCommand(String command) {
    if (command.toLowerCase().contains("navigate to")) {
      String address = command.replaceAll("navigate to", "").trim();
      getLatLngFromAddress(address);
    }
  }

  Future<void> fetchRoute(LatLng destination) async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng newPosition = LatLng(position.latitude, position.longitude);
    final String url =
                "https://router.project-osrm.org/route/v1/driving/${newPosition.longitude},${newPosition.latitude};${destination.longitude},${destination.latitude}?geometries=geojson";


    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['paths'].isNotEmpty) {
        String encodedPolyline = data['paths'][0]['points'];

        // Decode polyline
        List<PointLatLng> polylinePoints =
            PolylinePoints().decodePolyline(encodedPolyline);

        setState(() {
          _routePoints = polylinePoints
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();
          _routePoints = _routePoints;
          _currentPosition = newPosition;
          _destination = destination;
          lat = newPosition.latitude.toDouble();
          Long = newPosition.longitude.toDouble();
        });
      }
    } else {
      print("Failed to load route");
    }
  }

  bool isLoading = true;
  Map<String, dynamic> leadDetails = {};
  var leadId = 455;
  Future<void> fetchLeadDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/api/leads/${leadId}/'), // Using leadId in the API URL
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
        fetchRoute(_destination!);
      }
    } catch (e) {
      print("Error: $e");
    }
  }
    void openGoogleMaps() async {
    String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&origin=${_currentPosition.latitude},${_currentPosition.longitude}&destination=${_destination.latitude},${_destination.longitude}&travelmode=driving";
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("GraphHopper Navigation")),
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
                  Future.delayed(Duration(milliseconds: 500), () {
                    _mapController.move(_currentPosition, 15.0);
                  });
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
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: _currentPosition!,
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
                      point: _destination!,
                      child: Icon(Icons.location_pin,
                          color: Colors.green, size: 40),
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
                          //onPressed: isTracking ? stopTracking : startTracking,
                          // child: Text(
                          //     isTracking ? "Stop Tracking" : "Going For Lead"),
                          // style: ElevatedButton.styleFrom(
                          //   backgroundColor: Colors.transparent,
                          //   shadowColor: Colors.transparent,
                          //   padding: EdgeInsets.symmetric(
                          //     horizontal:
                          //         MediaQuery.of(context).size.width * 0.02,
                          //   ),
                          //   shape: RoundedRectangleBorder(
                          //     borderRadius: BorderRadius.circular(8.0),
                          //   ),
                          // ),
                          onPressed: () {},
                          child: Text(
                            "Going For Lead",
                            style: WidgetSupport.LoginButtonTextColor(),
                          ),
                        ),
                        // ElevatedButton(
                        //   onPressed: () {
                        //     // Navigator.push(
                        //     //   context,
                        //     //   MaterialPageRoute(
                        //     //     builder: (context) =>
                        //     //          DriverMapView(destination: _destination),
                        //     //   ),
                        //     // );
                        //   },
                        //   child: Text("Start Navigation"),
                        // ),
                        ElevatedButton(
                          onPressed: openGoogleMaps,
                          child: Text("Going For Lead"),
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
