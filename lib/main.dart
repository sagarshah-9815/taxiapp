import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyC4m3ymZxhZatmPS0FqPVUqJOpZ7teZodc",
          appId: "1:612970848752:web:1309d6aa10716cd756bd35",
          messagingSenderId: "612970848752",
          projectId: "taxiapp-7b639"));
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MyApp(),
    ),
  );
}
