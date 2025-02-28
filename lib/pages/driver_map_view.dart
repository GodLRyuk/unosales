import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';

class DriverMapView extends StatefulWidget {
  final LatLng destination;

  const DriverMapView({Key? key, required this.destination}) : super(key: key);

  @override
  _DriverMapViewState createState() => _DriverMapViewState();
}

class _DriverMapViewState extends State<DriverMapView> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(0, 0);
  List<LatLng> _routePoints = [];
  List<String> _instructions = []; // Stores turn-by-turn instructions
  FlutterTts _flutterTts = FlutterTts();
  int _currentInstructionIndex = 0; // Track current step

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setupTts();
  }

  // Setup text-to-speech
  void _setupTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Adjust speed if needed
  }

  // Speak instruction
  void _speakInstruction(String text) async {
    await _flutterTts.speak(text);
  }

  // Get user's current location
  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Ensure _mapController is used only after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapController != null) {
          _mapController.move(_currentPosition, 15.0);
        }
      });
      print("flocation");
      _fetchRoute();
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // Fetch route from OpenRouteService
  Future<void> _fetchRoute() async {
    print("ffffffff");
    const String apiKey =
        "5b3ce3597851110001cf6248c69a4cac7d204ad08965cee4a6faa5e9";
    final routeUrl = Uri.parse(
        "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${_currentPosition.longitude},${_currentPosition.latitude}&end=${widget.destination.longitude},${widget.destination.latitude}");

    try {
      final response = await http.get(routeUrl);
      print(response.statusCode);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(response.body);
        final List<dynamic> coordinates =
            data['routes'][0]['geometry']['coordinates'];
        List<LatLng> routePoints =
            coordinates.map((point) => LatLng(point[1], point[0])).toList();

        // Extract turn-by-turn instructions
        List<String> instructions = data['routes'][0]['segments'][0]['steps']
            .map<String>((step) => step['instruction'].toString())
            .toList();

        setState(() {
          _routePoints = routePoints;
          _instructions = instructions;
          print(_instructions);
        });

        // Speak first instruction
        if (_instructions.isNotEmpty) {
          _speakInstruction(_instructions[0]);
        }

        // Start tracking location for step-by-step navigation
        _trackDriverMovement();
      } else {
        print("Failed to fetch route");
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  // Track driver movement and give next instruction when approaching next step
  void _trackDriverMovement() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      LatLng newPosition = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = newPosition;
      });

      // Move map to new position
      _mapController.move(_currentPosition, 15.0);

      // Check if driver is near the next instruction point
      if (_currentInstructionIndex < _routePoints.length - 1) {
        double distanceToNextPoint = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          _routePoints[_currentInstructionIndex + 1].latitude,
          _routePoints[_currentInstructionIndex + 1].longitude,
        );

        if (distanceToNextPoint < 30) {
          // Trigger next instruction when 30m close
          _currentInstructionIndex++;
          if (_currentInstructionIndex < _instructions.length) {
            _speakInstruction(_instructions[_currentInstructionIndex]);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Driver Navigation")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _instructions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.directions_car,
                      color: index == _currentInstructionIndex
                          ? Colors.red
                          : Colors.blue),
                  title: Text(
                    _instructions[index],
                    style: TextStyle(
                        fontWeight: index == _currentInstructionIndex
                            ? FontWeight.bold
                            : FontWeight.normal),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
