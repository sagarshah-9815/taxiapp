import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'customer/customer_screen.dart';
import 'driver/driver_screen.dart';
import 'admin/admin_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          if (authService.currentUser == null) {
            return LoginScreen();
          } else {
            switch (authService.currentUser!.role) {
              case 'customer':
                return CustomerScreen();
              case 'driver':
                return DriverScreen();
              case 'admin':
                return AdminScreen();
              default:
                return LoginScreen();
            }
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
