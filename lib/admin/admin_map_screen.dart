import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../map/map_service.dart'; // Reuse your MapService

class AdminMapScreen extends StatefulWidget {
  final LatLng? startLocation;
  final LatLng? endLocation;
  final double? fare;

  AdminMapScreen({this.startLocation, this.endLocation, this.fare});

  @override
  _AdminMapScreenState createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
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
      if (startLocation != null && endLocation != null) {
        _getRoute();
      }
    });
  }

  Future<void> _getRoute() async {
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ride Route'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: startLocation ??
                  LatLng(27.7172, 85.3240), // Default to Kathmandu
              initialZoom: 13.0,
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
          if (widget.fare != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Fare: ${widget.fare!.toStringAsFixed(2)} NPR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
}
