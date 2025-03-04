import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/mytodolist.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:url_launcher/url_launcher.dart';

const String graphHopperApiKey =
    "5b3ce3597851110001cf6248c69a4cac7d204ad08965cee4a6faa5e9";

class FSAOSMRouteTracking extends StatefulWidget {
  final String leadId;
  const FSAOSMRouteTracking({super.key, required this.leadId});
  @override
  _FSAOSMRouteTrackingState createState() => _FSAOSMRouteTrackingState();
}

class _FSAOSMRouteTrackingState extends State<FSAOSMRouteTracking> {
  late MapController _mapController;
  LatLng _currentPosition = LatLng(0.0, 0.0);
  LatLng _destination = LatLng(0.0, 0.0);
  List<LatLng> _routePoints = [];
  List<LatLng> _movementPath = [];
  bool isRouteLoading = false;
  bool isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    getCurrentLocation();
    fetchLeadDetails();
    trackUserMovement();
    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      return;
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
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
        fetchRoute(_destination);
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("Location permissions are denied.");
      return;
    }

    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
      setState(() {
        _currentPosition = LatLng(position!.latitude, position.longitude);
      });
      _mapController.move(_currentPosition, 15.0);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // Future<void> getCurrentLocation() async {
  //   print("current position ");
  //   try {
  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );
  //     setState(() {
  //       _currentPosition = LatLng(position.latitude, position.longitude);
  //       print("Current Posi: $_currentPosition");
  //     });
  //     _mapController.move(_currentPosition, 15.0);
  //   } catch (e) {
  //     print("Error getting location: $e");
  //   }
  // }

  // void trackUserMovement() {
  //   _positionStream?.cancel(); // Cancel any existing stream
  //   _positionStream = Geolocator.getPositionStream(
  //     locationSettings: LocationSettings(
  //       accuracy: LocationAccuracy.high,
  //       distanceFilter: 1, // Update on every 1 meter movement
  //     ),
  //   ).listen((Position position) {
  //     if (mounted) {
  //       LatLng newPosition = LatLng(position.latitude, position.longitude);

  //       // Add the new position only if it differs significantly
  //       if (_routePoints.isEmpty ||
  //           Geolocator.distanceBetween(
  //                   _routePoints.last.latitude,
  //                   _routePoints.last.longitude,
  //                   newPosition.latitude,
  //                   newPosition.longitude) >=
  //               1) {
  //         setState(() {
  //           _currentPosition = newPosition;
  //           _routePoints.add(newPosition);

  //         });

  //         _mapController.move(newPosition, 15.0);
  //       }
  //     }
  //   }, onError: (error) {
  //     print("Error in position stream: $error");
  //   });
  // }

  void trackUserMovement() {
    print("tracking------------------");
    _positionStream?.cancel(); // Cancel any existing stream

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Update on every 1 meter movement
      ),
    ).listen((Position position) {
      if (mounted) {
        LatLng newPosition = LatLng(position.latitude, position.longitude);

        // Ensure we have a route from API
        if (_routePoints.isNotEmpty) {
          // Find the nearest point on the route
          LatLng closestPoint = _routePoints.first;
          double minDistance = double.infinity;

          for (LatLng point in _routePoints) {
            double distance = Geolocator.distanceBetween(point.latitude,
                point.longitude, newPosition.latitude, newPosition.longitude);
            if (distance < minDistance) {
              minDistance = distance;
              closestPoint = point;
            }
          }

          // Remove past points to keep route relevant
          _routePoints.removeWhere((point) =>
              Geolocator.distanceBetween(point.latitude, point.longitude,
                  newPosition.latitude, newPosition.longitude) <
              1);

          setState(() {
            _currentPosition = newPosition;

            // Keep the user near the predefined route
            _routePoints.insert(0, newPosition);

            // Ensure continuity in the route
            if (!_routePoints.contains(closestPoint)) {
              _routePoints.add(closestPoint);
            }
            print(_routePoints);
          });

          _mapController.move(newPosition, 15.0);
        }
      }
    }, onError: (error) {
      print("Error in position stream: $error");
    });
  }

  Future<void> fetchRoute(LatLng destination) async {
    setState(() {
      isRouteLoading = true;
    });
    try {
      final String url =
          "https://router.project-osrm.org/route/v1/driving/${_currentPosition.longitude},${_currentPosition.latitude};${destination.longitude},${destination.latitude}?geometries=geojson";
      // final String url =
      //     "https://graphhopper.com/api/1/route?points=${_currentPosition.latitude},${_currentPosition.longitude}&point=${destination.latitude},${destination.longitude}&profile=car&locale=en&calc_points=true&key=$graphHopperApiKey";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          List<dynamic> coordinates =
              data['routes'][0]['geometry']['coordinates'];
          setState(() {
            _routePoints =
                coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
            _destination = destination;
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

  void openGoogleMaps() async {
    String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&origin=${_currentPosition.latitude},${_currentPosition.longitude}&destination=${_destination.latitude},${_destination.longitude}&travelmode=driving";
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open Google Maps';
    }
  }

  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref("Lead Movement");
  StreamSubscription<Position>? _positionStream;
  bool isTracking = false;
  List<Map<String, dynamic>> path = [];
  Future<void> startTracking() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userInfo = prefs.getStringList('userInfo');
    String unm = userInfo?.isNotEmpty == true ? userInfo![0] : "UnknownUser";
    setState(() => isTracking = true);
    if (mounted) {
      setState(() {
        isFetchingLocation = true;
      });
    }

    try {
      // Get last known location or fetch new one if not available
      Position? position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          isFetchingLocation = false;
        });
      }
      // Store initial location in Firebase
      _storeLocationToFirebase(unm, position);

      // Listen for real-time updates (only when moved at least 1 meter)
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Only update when moving at least 1 meter
        ),
      ).listen((Position newPosition) {
        if (mounted) {
          setState(() {
            _currentPosition =
                LatLng(newPosition.latitude, newPosition.longitude);
          });
        }
        _storeLocationToFirebase(unm, newPosition);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  /// Helper function to store location in Firebase
  void _storeLocationToFirebase(String user, Position position) {
    Map<String, dynamic> newLocation = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _dbRef
        .child(user)
        .child(widget.leadId)
        .child(DateTime.now().millisecondsSinceEpoch.toString())
        .set(newLocation)
        .catchError((error) {
      print("Error storing data in Firebase: $error");
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    setState(() => isTracking = false);
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
                        builder: (context) => FSAMyTodoList(
                              searchQuery: '',
                            )));
              },
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isFetchingLocation)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // Ensures the column only takes necessary space
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10), // Space between loader and text
                    Text(
                      "Fetching location...",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: _currentPosition,
                        zoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        ),
                        PolylineLayer(
                          polylines: [
                            // This is the pre-fetched route from OSRM
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 4.0,
                              color: Colors.blue,
                            ),
                            // This is the dynamically updated movement path
                            Polyline(
                              points: _movementPath,
                              strokeWidth: 4.0,
                              color: Colors
                                  .red, // Use a different color for live movement tracking
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
                                  Icon(Icons.circle,
                                      color: Colors.blue, size: 20),
                                ],
                              ),
                            ),
                            Marker(
                              width: 40.0,
                              height: 40.0,
                              point: _destination,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.greenAccent.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Icon(Icons.circle,
                                      color: Colors.green, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isRouteLoading)
                          Center(child: CircularProgressIndicator()),
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
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Name: ${leadDetails['first_name']} ${leadDetails['middle_name']} ${leadDetails['last_name']}",
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF2C2B2B)),
                          ),
                          Text(
                            "Phone Number: +${leadDetails['phone_number']} ",
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF2C2B2B)),
                          ),
                          Text(
                            "Zip: ${leadDetails['zip']} ",
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF2C2B2B)),
                          ),
                          Text(
                            "Location: ${leadDetails['location']} ",
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF2C2B2B)),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01,
                          ),
                          Text(
                            "Destination:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Address: ${leadDetails['address1']} ${leadDetails['address2']}",
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF2C2B2B)),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    if (isTracking) {
                                      stopTracking();
                                    } else {
                                      startTracking();
                                      openGoogleMaps();
                                    }
                                  },
                                  child: Text(
                                    isTracking
                                        ? "Stop Tracking"
                                        : "Going For Lead",
                                    style: WidgetSupport.LoginButtonTextColor(),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
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
            ),
        ],
      ),
    );
  }
}
