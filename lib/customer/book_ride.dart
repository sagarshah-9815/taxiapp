import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../database/firebase_service.dart';
import '../map/map_screen.dart';
import '../map/map_service.dart';
import '../models/ride.dart';

class BookRideScreen extends StatefulWidget {
  @override
  _BookRideScreenState createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book a Ride')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _startController,
              decoration: InputDecoration(labelText: 'Start Location'),
            ),
            TextField(
              controller: _endController,
              decoration: InputDecoration(labelText: 'End Location'),
            ),
            ElevatedButton(
              child: Text('Book Ride'),
              onPressed: () async {
                // In a real app, you would use geocoding to convert addresses to coordinates
                LatLng start = LatLng(27.7172, 85.3240); // Example: Kathmandu
                LatLng end = LatLng(27.6588, 85.3247); // Example: Patan

                List<LatLng> route = await MapService.getRoute(start, end);

                // Use Distance class from latlong2 to calculate the distance
                final Distance distance = Distance();
                double totalDistance = 0;
                for (int i = 0; i < route.length - 1; i++) {
                  totalDistance += distance(route[i], route[i + 1]);
                }

                double fare = MapService.calculateFare(totalDistance);

                Ride ride = Ride(
                  id: '',
                  customerId: 'customer_id', // Replace with actual customer ID
                  driverId: '',
                  start: _startController.text,
                  end: _endController.text,
                  status: 'pending',
                  fare: fare,
                );

                await _firebaseService.createRide(ride);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
