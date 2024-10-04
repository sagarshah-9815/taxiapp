import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import '../auth/auth_service.dart';
import '../models/ride.dart';
import '../database/firebase_service.dart';

class CustomerScreen extends StatefulWidget {
  @override
  _CustomerScreenState createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final MapController _mapController = MapController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  bool _isLoading = false;
  List<LatLng> _routePoints = [];
  Map<String, dynamic> _driverLocations = {};
  String? _destinationName;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToDriverLocations();
  }

  void _listenToDriverLocations() {
    _database.child('driver_locations').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _driverLocations =
              Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLocation!, 13);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _getLocationName(LatLng location) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      }
    } catch (e) {
      print('Error fetching location name: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ride Booking'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? LatLng(0, 0),
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
                    points: _routePoints,
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
          if (_isLoading) Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                if (_destinationLocation != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destination',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(_destinationName ?? 'Loading...'),
                          SizedBox(height: 8),
                          Text(
                            '${_destinationLocation!.latitude.toStringAsFixed(4)}, ${_destinationLocation!.longitude.toStringAsFixed(4)}',
                          ),
                          if (_routePoints.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              'Estimated Fare: ${_calculateFare(_routePoints).toStringAsFixed(2)} NPR',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 8),
                ElevatedButton(
                  child: Text(_destinationLocation == null
                      ? 'Tap to Set Destination'
                      : 'Book Ride'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _destinationLocation == null ? null : _bookRide,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.my_location),
        backgroundColor: Colors.teal,
        onPressed: () {
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 13);
          } else {
            _getCurrentLocation();
          }
        },
      ),
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    if (_currentLocation != null) {
      markers.add(Marker(
        width: 80.0,
        height: 80.0,
        point: _currentLocation!,
        child: Icon(Icons.location_on, color: Colors.blue, size: 40),
      ));
    }
    if (_destinationLocation != null) {
      markers.add(Marker(
        width: 80.0,
        height: 80.0,
        point: _destinationLocation!,
        child: Icon(Icons.flag, color: Colors.red, size: 40),
      ));
    }

    _driverLocations.forEach((driverId, locationData) {
      LatLng driverLocation = LatLng(
        locationData['latitude'] as double,
        locationData['longitude'] as double,
      );
      markers.add(Marker(
        width: 80.0,
        height: 80.0,
        point: driverLocation,
        child: GestureDetector(
          onTap: () => _showDriverInfo(driverId, locationData),
          child: Icon(Icons.local_taxi, color: Colors.green, size: 40),
        ),
      ));
    });

    return markers;
  }

  void _showDriverInfo(String driverId, Map<String, dynamic> locationData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Driver Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver ID: $driverId'),
            Text('Location: ${locationData['location_name'] ?? 'Unknown'}'),
            Text(
                'Last Updated: ${DateTime.fromMillisecondsSinceEpoch(locationData['timestamp'] as int).toString()}'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _destinationLocation = point;
      _isLoading = true;
      _destinationName = null;
    });

    try {
      _destinationName = await _getLocationName(point);
      List<LatLng> route =
          await MapService.getRoute(_currentLocation!, _destinationLocation!);
      setState(() {
        _routePoints = route;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get route: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _bookRide() async {
    if (_currentLocation == null || _destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please set both start and end locations')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      double fare = _calculateFare(_routePoints);

      String? userId = context.read<AuthService>().currentUser?.id;

      if (userId == null) {
        throw Exception('No user logged in');
      }

      Ride ride = Ride(
        id: '',
        customerId: userId,
        driverId: '',
        start: '${_currentLocation!.latitude},${_currentLocation!.longitude}',
        end:
            '${_destinationLocation!.latitude},${_destinationLocation!.longitude}',
        status: 'pending',
        fare: fare,
      );

      await _firebaseService.createRide(ride);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride booked successfully!')),
      );

      // Here you might want to navigate to a ride tracking screen or show more details
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book ride: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateFare(List<LatLng> route) {
    double distanceInMeters = 0;
    for (int i = 0; i < route.length - 1; i++) {
      distanceInMeters +=
          Distance().as(LengthUnit.Meter, route[i], route[i + 1]);
    }
    return MapService.calculateFare(distanceInMeters);
  }
}

class MapService {
  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/driving/';

  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final response = await http.get(Uri.parse(
        '$_baseUrl${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> coordinates =
          data['routes'][0]['geometry']['coordinates'];
      return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
    } else {
      throw Exception('Failed to load route');
    }
  }

  static double calculateFare(double distanceInMeters) {
    // Base fare: 50 NPR
    // Per kilometer rate: 20 NPR
    // Minimum fare: 100 NPR
    double fareInNPR = 50 + (distanceInMeters / 1000) * 20;
    return fareInNPR < 100 ? 100 : fareInNPR;
  }

  static List<LatLng> dijkstra(List<LatLng> graph, LatLng start, LatLng end) {
    final Distance distanceCalculator = Distance();

    Map<LatLng, double> distances = {};
    Map<LatLng, LatLng?> previousNodes = {};
    List<LatLng> unvisited = List.from(graph);

    for (var node in graph) {
      distances[node] = node == start ? 0 : double.infinity;
      previousNodes[node] = null;
    }

    while (unvisited.isNotEmpty) {
      LatLng current =
          unvisited.reduce((a, b) => distances[a]! < distances[b]! ? a : b);

      if (current == end) break;

      unvisited.remove(current);

      for (var neighbor in graph.where((node) => unvisited.contains(node))) {
        double alt =
            distances[current]! + distanceCalculator(current, neighbor);
        if (alt < distances[neighbor]!) {
          distances[neighbor] = alt;
          previousNodes[neighbor] = current;
        }
      }
    }

    List<LatLng> path = [];
    LatLng? current = end;
    while (current != null) {
      path.add(current);
      current = previousNodes[current];
    }
    return path.reversed.toList();
  }
}
