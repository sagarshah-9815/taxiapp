import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/auth_service.dart';
import '../map/map_screen.dart';
import '../models/ride.dart';
import '../database/firebase_service.dart';

class DriverScreen extends StatefulWidget {
  @override
  _DriverScreenState createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Ride> availableRides = [];
  LatLng? customerStartLocation;
  String? _currentLocationName;

  @override
  void initState() {
    super.initState();
    _fetchAvailableRides();
    _startLocationUpdates();
  }

  void _fetchAvailableRides() {
    _firebaseService.getRides().listen((rides) {
      setState(() {
        availableRides =
            rides.where((ride) => ride.status == 'pending').toList();
      });
    });
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updateDriverLocation(position);
      _getLocationName(position);
    });
  }

  void _updateDriverLocation(Position position) {
    final driverId = context.read<AuthService>().currentUser?.id;
    if (driverId != null) {
      _database.child('driver_locations').child(driverId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': ServerValue.timestamp,
      });
    }
  }

  Future<void> _getLocationName(Position position) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final locationName = data['display_name'];
        setState(() {
          _currentLocationName = locationName;
        });
        _updateLocationNameInDatabase(locationName);
      }
    } catch (e) {
      print('Error fetching location name: $e');
    }
  }

  void _updateLocationNameInDatabase(String locationName) {
    final driverId = context.read<AuthService>().currentUser?.id;
    if (driverId != null) {
      _database.child('driver_locations').child(driverId).update({
        'location_name': locationName,
      });
    }
  }

  void _acceptRide(Ride ride) async {
    ride.driverId = context.read<AuthService>().currentUser?.id ?? '';
    ride.status = 'accepted';
    await _firebaseService.updateRideStatus(ride.id, ride.status);
    setState(() {
      availableRides.remove(ride);
    });

    customerStartLocation = LatLng(
      double.parse(ride.start.split(',')[0]),
      double.parse(ride.start.split(',')[1]),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          startLocation: customerStartLocation,
          endLocation: LatLng(
            double.parse(ride.end.split(',')[0]),
            double.parse(ride.end.split(',')[1]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Driver Dashboard')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, Driver!'),
            SizedBox(height: 20),
            Text('Current Location: ${_currentLocationName ?? "Updating..."}'),
            SizedBox(height: 20),
            Text('Available Rides:'),
            Expanded(
              child: ListView.builder(
                itemCount: availableRides.length,
                itemBuilder: (context, index) {
                  final ride = availableRides[index];
                  return ListTile(
                    title: Text('Ride ID: ${ride.id}'),
                    subtitle: Text(
                        'Start: ${ride.start}\nEnd: ${ride.end}\nFare: ${ride.fare} NPR'),
                    trailing: ElevatedButton(
                      child: Text('Accept'),
                      onPressed: () => _acceptRide(ride),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Logout'),
              onPressed: () => context.read<AuthService>().signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
