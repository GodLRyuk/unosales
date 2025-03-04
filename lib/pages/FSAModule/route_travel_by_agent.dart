import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:unosfa/pages/FSAModule/mytodolist.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class AgentRouteTraveled extends StatefulWidget {
  @override
  _AgentRouteTraveledState createState() => _AgentRouteTraveledState();
}

class _AgentRouteTraveledState extends State<AgentRouteTraveled> {
  final MapController _mapController = MapController();
  // LatLng _currentPosition = LatLng(00.00, 00.00);
  LatLng _currentPosition = LatLng(22.571084, 88.432457);

  List<LatLng> _destinations = [];
  List<LatLng> _routePoints = [];
  List<String> _clientNames = [];
  List<dynamic> allleadsdetails = [];
  bool isRouteLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLeadDetails();
    getCurrentLocation();
  }

  Map<String, dynamic> leadDetails = {};

  Future<void> fetchLeadDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        leadDetails = json.decode(response.body);
        setState(() {
          allleadsdetails =
              data['results'] ?? []; // Ensure leads list is updated in UI
        });
        List<dynamic> leads = data['results'] ?? [];
        for (var lead in leads) {
          String address = "${lead['address1']} ${lead['address2']}".trim();
          String ClientNAme =
              "${lead['first_name']} ${lead['middle_name']} ${lead['last_name']}"
                  .trim();
          if (address.isNotEmpty) {
            await getLatLngFromAddress(address);
            _clientNames.add(ClientNAme);
          }
        }

        if (_destinations.isNotEmpty) {
          findAndFetchFullRoute();
        }
      } else {
        throw Exception('Failed to load lead details');
      }
    } catch (e) {
      print('Error fetching lead details: $e');
    }
  }

  Future<void> getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        LatLng destination =
            LatLng(locations.first.latitude, locations.first.longitude);

        setState(() {
          _destinations.add(destination);
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  /// Sort destinations and fetch the route through all points
  void findAndFetchFullRoute() {
    if (_destinations.isEmpty) return;

    // Sort destinations by nearest to the current position
    _destinations.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    // Fetch route passing through all destinations
    fetchMultiStopRoute();
  }

  Future<void> fetchMultiStopRoute() async {
    setState(() {
      isRouteLoading = true;
    });

    try {
      const String apiKey =
          "5b3ce3597851110001cf6248c69a4cac7d204ad08965cee4a6faa5e9"; // Replace with your API key

      // Construct waypoints for ORS
      List<List<double>> coordinates = [
        [_currentPosition.longitude, _currentPosition.latitude], // Start point
        ..._destinations
            .map((dest) => [dest.longitude, dest.latitude])
            .toList() // Destinations
      ];

      final String url =
          "https://api.openrouteservice.org/v2/directions/driving-car/geojson";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": apiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "coordinates": coordinates,
          "instructions": false, // Disable turn-by-turn instructions
          "geometry": true, // Get road-following route geometry
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'].isNotEmpty) {
          List<dynamic> routeCoordinates =
              data['features'][0]['geometry']['coordinates'];

          setState(() {
            _routePoints = routeCoordinates
                .map((coord) => LatLng(coord[1], coord[0])) // Convert to LatLng
                .toList();
            isRouteLoading = false;
          });
        }
      } else {
        print("Failed to load route: ${response.body}");
      }
    } catch (e) {
      print("Error fetching route: $e");
    }

    setState(() {
      isRouteLoading = false;
    });
  }

  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(22.571084, 88.432457);
        print("Current Posi: $_currentPosition");
      });
      _mapController.move(_currentPosition, 15.0);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFc433e0), Color(0xFF9a37ae)],
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
                Image.asset('images/logo.PNG', height: 30),
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
                    builder: (context) => FSAMyTodoList(searchQuery: ''),
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
            flex: 7,
            child: FlutterMap(
              // mapController: _mapController,
              options: MapOptions(
                center: _currentPosition,
                zoom: 11,
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
                      color: Colors.lightBlueAccent,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: _destinations.asMap().entries.map(
                    (entry) {
                      int index = entry.key;
                      LatLng destination = entry.value;
                      String clientName = _clientNames[
                          index]; // Ensure you maintain a list of client names

                      return Marker(
                        width: MediaQuery.of(context).size.width * 1.0,
                        height: 70.0,
                        point: destination,
                        child: Column(
                          children: [
                            Container(
                              // padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                // boxShadow: [
                                //   BoxShadow(
                                //       color: Colors.white, blurRadius: 4),
                                // ],
                              ),
                              child: Text(
                                clientName.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFc433e0)),
                              ),
                            ),
                            SizedBox(
                                height: 4), // Spacing between text and marker
                            Image.asset("images/icons8-location.gif",
                                width: 40, height: 40),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      "Leads Details:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    for (var lead in allleadsdetails) ...[
                      Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            top: BorderSide(
                                color: Color(0xFF640D78), width: 1.0),
                            bottom: BorderSide(
                                color: Color(0xFF640D78), width: 1.0),
                            left: BorderSide(
                                color: Color(0xFF640D78), width: 5.0),
                            right: BorderSide(
                                color: Color(0xFF640D78), width: 1.0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Name:",
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  " ${lead['first_name']} ${lead['middle_name'] ?? ''} ${lead['last_name']}"
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Phone Number:",
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  " + ${lead['phone_number']}".toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Address:",
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500),
                                ),
                                Flexible(
                                  child: Text(
                                    "${lead['address1']} ${lead['address2']}",
                                    style: TextStyle(
                                        fontSize: 16, color: Color(0xFF2C2B2B)),
                                    softWrap: true,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
