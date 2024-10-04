import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'map_service.dart';

class MapScreen extends StatefulWidget {
  final LatLng? startLocation;
  final LatLng? endLocation;

  MapScreen({this.startLocation, this.endLocation});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> routePoints = [];
  LatLng? startLocation;
  LatLng? endLocation;
  MapController mapController = MapController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    startLocation = widget.startLocation;
    endLocation = widget.endLocation;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          _showSnackBar('Location permissions are denied.');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      mapController.move(LatLng(position.latitude, position.longitude), 13.0);
      setState(() {
        startLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      _showSnackBar('Error getting current location: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Locations'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(0, 0),
              initialZoom: 13.0,
              onTap: _handleMapTap,
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
                    points: routePoints,
                    strokeWidth: 4.0,
                    color: Colors.blue,
                  ),
                ],
              ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tap to set locations:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    _buildLocationInfo('Start', startLocation, Colors.red),
                    SizedBox(height: 4),
                    _buildLocationInfo('End', endLocation, Colors.green),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (startLocation != null && endLocation != null)
            FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, {
                  'start': startLocation,
                  'end': endLocation,
                });
              },
              label: Text('Confirm Locations'),
              icon: Icon(Icons.check),
              backgroundColor: Colors.teal,
            ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _getCurrentLocation,
            child: Icon(Icons.my_location),
            backgroundColor: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String label, LatLng? location, Color color) {
    return Row(
      children: [
        Icon(Icons.location_on, color: color, size: 16),
        SizedBox(width: 4),
        Text(
          '$label: ${location != null ? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}' : "Not set"}',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    if (startLocation != null) {
      markers.add(Marker(
        width: 80.0,
        height: 80.0,
        point: startLocation!,
        child: Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }
    if (endLocation != null) {
      markers.add(Marker(
        width: 80.0,
        height: 80.0,
        point: endLocation!,
        child: Icon(Icons.flag, color: Colors.green, size: 40),
      ));
    }
    return markers;
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      if (startLocation == null) {
        startLocation = point;
      } else if (endLocation == null) {
        endLocation = point;
        _getRoute();
      } else {
        startLocation = point;
        endLocation = null;
        routePoints.clear();
      }
    });
  }

  void _getRoute() async {
    if (startLocation != null && endLocation != null) {
      setState(() {
        isLoading = true;
      });

      try {
        List<LatLng> route =
            await MapService.getRoute(startLocation!, endLocation!);
        setState(() {
          routePoints = route;
        });
      } catch (e) {
        _showSnackBar('Error getting route: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
