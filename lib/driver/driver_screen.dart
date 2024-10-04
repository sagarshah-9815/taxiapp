import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
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
  List<Ride> availableRides = [];
  LatLng? customerStartLocation;

  @override
  void initState() {
    super.initState();
    _fetchAvailableRides();
  }

  void _fetchAvailableRides() {
    _firebaseService.getRides().listen((rides) {
      setState(() {
        availableRides =
            rides.where((ride) => ride.status == 'pending').toList();
      });
    });
  }

  void _acceptRide(Ride ride) async {
    // Update the ride status and assign the driver
    ride.driverId = context.read<AuthService>().currentUser?.id ?? '';
    ride.status = 'accepted';

    await _firebaseService.updateRideStatus(ride.id, ride.status);
    setState(() {
      availableRides.remove(ride);
    });

    // Navigate to the map with the customer's start location
    customerStartLocation = LatLng(
      double.parse(ride.start.split(',')[0]), // Parse latitude
      double.parse(ride.start.split(',')[1]), // Parse longitude
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          startLocation: customerStartLocation,
          endLocation: LatLng(
            // You might want to provide the end location or modify this
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
              onPressed: () {
                context.read<AuthService>().signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
