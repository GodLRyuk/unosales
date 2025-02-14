import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverMapView extends StatefulWidget {
  final LatLng destination;

  const DriverMapView({Key? key, required this.destination}) : super(key: key);

  @override
  _DriverMapViewState createState() => _DriverMapViewState();
}

class _DriverMapViewState extends State<DriverMapView> {
  LatLng _currentPosition = LatLng(0, 0);
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _mapController = MapController(); 
  }

  // Get the user's current location
  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _updateCurrentPosition(_currentPosition);
    });
  }
  void _updateCurrentPosition(LatLng newPosition) {
    setState(() {
      _currentPosition = newPosition;
    });
    _mapController.move(newPosition, 7.0);
  }

  // Open OpenStreetMap for navigation
  void _openOSMNavigation() async {
  final osmUrl =
      'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=${_currentPosition.latitude},${_currentPosition.longitude};${widget.destination.latitude},${widget.destination.longitude}';


  if (await canLaunch(osmUrl)) {
    await launch(osmUrl);
  } else {
    throw 'Could not launch OpenStreetMap navigation';
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Driver Map View")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _currentPosition,
          zoom: 15.0,
          onMapReady: () {
                  _mapController.move(_currentPosition, 15.0);
                }
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              // User's location marker
              Marker(
                width: 40.0,
                height: 40.0,
                point: _currentPosition,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: Duration(seconds: 1),
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
              // Destination marker
              Marker(
                width: 40.0,
                height: 40.0,
                point: widget.destination,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openOSMNavigation,
        icon: Icon(Icons.directions),
        label: Text("Start Navigation"),
      ),
    );
  }
}
