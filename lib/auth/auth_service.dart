import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:project/database/firebase_service.dart';
import '../models/user.dart'; // Make sure this contains AppUser
// Ensure you import your Customer model
// Ensure you import your Driver model
// Import your FirebaseService

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService =
      FirebaseService(); // Create an instance of FirebaseService
  AppUser? _user;

  AppUser? get currentUser => _user;

  // Sign In method
  Future<bool> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      if (user != null) {
        _user = await _getUserFromFirestore(user.uid);
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      print("Unknown error during sign-in: ${e.toString()}");
    }
    return false;
  }

  // Register method (single method for both customer and driver)
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    String? license,
    String? vehicleNumber,
    required String role,
    DateTime? dateOfBirth, // Optional for drivers
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      if (user != null) {
        // Depending on the role, create a customer or driver in Firestore
        if (role == 'customer') {
          await _createCustomerInFirestore(
              user.uid, email, name, phoneNumber, dateOfBirth!);
        } else if (role == 'driver') {
          await _createDriverInFirestore(
              user.uid, email, name, phoneNumber, license!, vehicleNumber!);
        }

        // Add user to the users collection
        await _firebaseService.addUser(user.uid, email, role);

        _user = AppUser(id: user.uid, email: email, role: role);
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      print("Unknown error during registration: ${e.toString()}");
    }
    return false;
  }

  // Sign out method
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // Get user from Firestore
  Future<AppUser?> _getUserFromFirestore(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser(
          id: uid,
          email: doc['email'],
          role: doc['role'],
        );
      }
    } catch (e) {
      print("Error fetching user from Firestore: ${e.toString()}");
    }
    return null;
  }

  // Create customer in Firestore
  Future<void> _createCustomerInFirestore(String uid, String email, String name,
      String phoneNumber, DateTime dateOfBirth) async {
    try {
      await _firestore.collection('customers').doc(uid).set({
        'email': email,
        'name': name,
        'phone_number': phoneNumber,
        'date_of_birth': dateOfBirth,
      });
    } catch (e) {
      print("Error creating customer in Firestore: ${e.toString()}");
    }
  }

  // Create driver in Firestore
  Future<void> _createDriverInFirestore(String uid, String email, String name,
      String phoneNumber, String license, String vehicleNumber) async {
    try {
      await _firestore.collection('drivers').doc(uid).set({
        'email': email,
        'name': name,
        'phone_number': phoneNumber,
        'license': license,
        'vehicle_number': vehicleNumber,
      });
    } catch (e) {
      print("Error creating driver in Firestore: ${e.toString()}");
    }
  }

  // Handle FirebaseAuth errors
  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        print("The email is already in use.");
        break;
      case 'weak-password':
        print("The password is too weak.");
        break;
      case 'user-not-found':
        print("No user found with this email.");
        break;
      case 'wrong-password':
        print("Wrong password provided.");
        break;
      default:
        print("Authentication error: ${e.message}");
    }
  }
}
