import 'package:flutter/material.dart';

class DriverRegisterScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Driver Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Nepali Phone Number'),
            ),
            TextField(
              controller: licenseController,
              decoration: InputDecoration(labelText: 'Driver\'s License'),
            ),
            TextField(
              controller: vehicleNumberController,
              decoration: InputDecoration(labelText: 'Vehicle Number'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Register'),
              onPressed: () async {
                // Input validation
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty ||
                    licenseController.text.isEmpty ||
                    vehicleNumberController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill out all fields')),
                  );
                  return;
                }
                // Show loading indicator, call register function, etc.
                // Similar to your existing register logic.
              },
            ),
          ],
        ),
      ),
    );
  }
}
