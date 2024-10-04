import 'package:flutter/material.dart';
import 'package:project/admin/admin_map_screen.dart'; // Updated to use AdminMapScreen
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../database/firebase_service.dart';
import '../models/ride.dart';
import '../models/driver.dart';
import '../models/customer.dart';
import 'package:latlong2/latlong.dart';

class AdminScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Admin!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context: context,
                    title: 'Rides',
                    stream: _firebaseService.getRides(),
                    onTap: () =>
                        _showDetailScreen(context, DetailScreenType.rides),
                  ),
                  _buildDashboardCard(
                    context: context,
                    title: 'Drivers',
                    stream: _firebaseService.getDrivers(),
                    onTap: () =>
                        _showDetailScreen(context, DetailScreenType.drivers),
                  ),
                  _buildDashboardCard(
                    context: context,
                    title: 'Customers',
                    stream: _firebaseService.getCustomers(),
                    onTap: () =>
                        _showDetailScreen(context, DetailScreenType.customers),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard<T>({
    required BuildContext context,
    required String title,
    required Stream<List<T>> stream,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.length : 0;
        return Card(
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailScreen(BuildContext context, DetailScreenType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(type: type),
      ),
    );
  }
}

enum DetailScreenType { rides, drivers, customers }

class DetailScreen extends StatelessWidget {
  final DetailScreenType type;
  final FirebaseService _firebaseService = FirebaseService();

  DetailScreen({required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: _buildBody(),
    );
  }

  String _getTitle() {
    switch (type) {
      case DetailScreenType.rides:
        return 'All Rides';
      case DetailScreenType.drivers:
        return 'All Drivers';
      case DetailScreenType.customers:
        return 'All Customers';
    }
  }

  Widget _buildBody() {
    switch (type) {
      case DetailScreenType.rides:
        return _buildRidesTab();
      case DetailScreenType.drivers:
        return _buildDriversTab();
      case DetailScreenType.customers:
        return _buildCustomersTab();
    }
  }

  Widget _buildRidesTab() {
    return StreamBuilder<List<Ride>>(
      stream: _firebaseService.getRides(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        List<Ride> rides = snapshot.data!;
        return ListView.builder(
          itemCount: rides.length,
          itemBuilder: (context, index) {
            Ride ride = rides[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text('${ride.start} to ${ride.end}'),
                subtitle: Text(
                    'Status: ${ride.status}, Fare: ${ride.fare.toStringAsFixed(2)} NPR'),
                onTap: () => _showRideOnMap(context, ride),
              ),
            );
          },
        );
      },
    );
  }

  void _showRideOnMap(BuildContext context, Ride ride) {
    LatLng? startLocation = _convertToLatLng(ride.start);
    LatLng? endLocation = _convertToLatLng(ride.end);

    if (startLocation != null && endLocation != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminMapScreen(
            startLocation: startLocation,
            endLocation: endLocation,
            fare: ride.fare,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid ride locations')),
      );
    }
  }

  LatLng? _convertToLatLng(String location) {
    List<String> parts = location.split(',');
    if (parts.length == 2) {
      double? lat = double.tryParse(parts[0]);
      double? lng = double.tryParse(parts[1]);
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  Widget _buildDriversTab() {
    return StreamBuilder<List<Driver>>(
      stream: _firebaseService.getDrivers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        List<Driver> drivers = snapshot.data!;
        return ListView.builder(
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            Driver driver = drivers[index];
            return ExpansionTile(
              title: Text(driver.name),
              subtitle:
                  Text('Earnings: ${driver.earnings.toStringAsFixed(2)} NPR'),
              children: [
                StreamBuilder<List<Ride>>(
                  stream: _firebaseService.getRidesForDriver(driver.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }
                    List<Ride> rides = snapshot.data!;
                    return Column(
                      children: rides
                          .map((ride) => ListTile(
                                title: Text('${ride.start} to ${ride.end}'),
                                subtitle: Text(
                                    'Status: ${ride.status}, Fare: ${ride.fare.toStringAsFixed(2)} NPR'),
                                onTap: () => _showRideOnMap(context, ride),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCustomersTab() {
    return StreamBuilder<List<Customer>>(
      stream: _firebaseService.getCustomers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        List<Customer> customers = snapshot.data!;
        return ListView.builder(
          itemCount: customers.length,
          itemBuilder: (context, index) {
            Customer customer = customers[index];
            return ExpansionTile(
              title: Text(customer.name),
              subtitle: Text('Phone: ${customer.phoneNumber}'),
              children: [
                StreamBuilder<List<Ride>>(
                  stream: _firebaseService.getRidesForCustomer(customer.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }
                    List<Ride> rides = snapshot.data!;
                    return Column(
                      children: rides
                          .map((ride) => ListTile(
                                title: Text('${ride.start} to ${ride.end}'),
                                subtitle: Text(
                                    'Status: ${ride.status}, Fare: ${ride.fare.toStringAsFixed(2)} NPR'),
                                onTap: () => _showRideOnMap(context, ride),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
