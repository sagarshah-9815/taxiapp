import 'package:flutter/material.dart';
import '../database/firebase_service.dart';
import '../models/ride.dart';
import '../models/driver.dart';
import '../models/customer.dart';

class CombinedAdminScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin Dashboard'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Rides'),
              Tab(text: 'Drivers'),
              Tab(text: 'Customers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRidesTab(),
            _buildDriversTab(),
            _buildCustomersTab(),
          ],
        ),
      ),
    );
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
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Implement ride details view
                },
              ),
            );
          },
        );
      },
    );
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
