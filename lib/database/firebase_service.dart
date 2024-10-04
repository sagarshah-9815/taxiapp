import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/models/customer.dart';
import 'package:project/models/driver.dart';
import '../models/ride.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _ridesCollection;
  late final CollectionReference _driversCollection;
  late final CollectionReference _customersCollection;

  FirebaseService() {
    _ridesCollection = _firestore.collection('rides');
    _driversCollection = _firestore.collection('drivers');
    _customersCollection = _firestore.collection('customers');
  }

  Future<void> createRide(Ride ride) async {
    try {
      await _ridesCollection.add(ride.toMap());
    } catch (e) {
      print('Error creating ride: $e');
      rethrow;
    }
  }

  Stream<List<Ride>> getRides() {
    return _ridesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
              (doc) => Ride.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<void> updateRideStatus(String rideId, String status) async {
    try {
      await _ridesCollection.doc(rideId).update({'status': status});
    } catch (e) {
      print('Error updating ride status: $e');
      rethrow;
    }
  }

  Future<void> updateDriverEarnings(String driverId, double amount) async {
    try {
      await _driversCollection.doc(driverId).update({
        'earnings': FieldValue.increment(amount),
      });
    } catch (e) {
      print('Error updating driver earnings: $e');
      rethrow;
    }
  }

  Stream<List<Driver>> getDrivers() {
    return _driversCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Driver.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Stream<List<Customer>> getCustomers() {
    return _customersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // New method to fetch rides for a specific customer
  Stream<List<Ride>> getRidesForCustomer(String customerId) {
    return _ridesCollection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
              (doc) => Ride.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // New method to add user to the users collection
  Future<void> addUser(String uid, String email, String role) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'role': role,
      });
    } catch (e) {
      print('Error adding user to Firestore: $e');
      rethrow;
    }
  }

  // New method to fetch accepted rides for a specific driver
  Stream<List<Ride>> getRidesForDriver(String driverId) {
    return _ridesCollection
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
              (doc) => Ride.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }
}
