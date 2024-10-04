import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phoneNumber; // Assuming this will be the Nepali phone number
  final DateTime dateOfBirth; // Add this for date of birth

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.dateOfBirth,
  });

  factory Customer.fromMap(Map<String, dynamic> data, String id) {
    return Customer(
      id: id,
      name: data['name'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      dateOfBirth:
          (data['date_of_birth'] as Timestamp).toDate(), // Adjust as necessary
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth, // Store as Timestamp in Firestore
    };
  }
}
