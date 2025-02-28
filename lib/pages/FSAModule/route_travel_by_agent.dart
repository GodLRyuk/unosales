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

class AgentRouteTraveled extends StatefulWidget {
  @override
  _AgentRouteTraveledState createState() => _AgentRouteTraveledState();
}

class _AgentRouteTraveledState extends State<AgentRouteTraveled> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(22.5697375, 88.4311852);
  List<LatLng> _destinations = [];
  List<LatLng> _routePoints = [];
  bool isRouteLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLeadDetails();
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
        List<dynamic> leads = data['results'] ?? [];

        leads.addAll(leads.map((item) => {
              'name':
                  '${item['first_name'] ?? ''} ${item['middle_name'] ?? ''} ${item['last_name'] ?? ''}'
                      .trim(),
              'phone': item['phone_number']?.toString() ?? '',
              'id': item['id']?.toString() ?? '',
            }));
        if (leads.isEmpty) {
          print("No leads found.");
          return;
        }

        for (var lead in leads) {
          String address = "${lead['address1']} ${lead['address2']}".trim();
          if (address.isNotEmpty) {
            await getLatLngFromAddress(address);
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
      // Create OSRM API URL with multiple waypoints
      String waypoints =
          "${_currentPosition.longitude},${_currentPosition.latitude}";
      for (var dest in _destinations) {
        waypoints += ";${dest.longitude},${dest.latitude}";
      }

      final String url =
          "https://router.project-osrm.org/route/v1/driving/$waypoints?geometries=geojson";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          List<dynamic> coordinates =
              data['routes'][0]['geometry']['coordinates'];

          setState(() {
            _routePoints =
                coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
            isRouteLoading = false;
          });
        }
      } else {
        print("Failed to load route");
      }
    } catch (e) {
      print("Error fetching route: $e");
    }

    setState(() {
      isRouteLoading = false;
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
            flex: 6,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentPosition,
                zoom: 13,
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
                              color: Colors.blue.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Icon(Icons.circle, color: Colors.blue, size: 20),
                        ],
                      ),
                    ),
                    ..._destinations.asMap().entries.map(
                      (entry) {
                        // int index = entry.key + 1;
                        LatLng destination = entry.value;
                        return Marker(
                            width: 40.0,
                            height: 40.0,
                            point: destination,
                            child: Image.asset("images/icons8-location.gif"));
                      },
                    ).toList(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
