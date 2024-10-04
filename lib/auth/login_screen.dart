import 'package:flutter/material.dart';
import 'package:project/customer/customer_screen.dart';
import 'package:project/driver/driver_screen.dart';
import 'package:project/models/user.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'register_screen.dart'; // Import your CustomerScreen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 50),
                _buildLogo(),
                SizedBox(height: 30),
                _buildCard(),
                SizedBox(height: 20),
                _buildLoginButton(),
                SizedBox(height: 10),
                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.teal,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.local_taxi,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(emailController, 'Email', Icons.email),
            SizedBox(height: 16),
            _buildTextField(passwordController, 'Password', Icons.lock,
                isPassword: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Login',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _login,
    );
  }

  Widget _buildRegisterButton() {
    return TextButton(
      child: Text(
        'Don\'t have an account? Register',
        style: TextStyle(color: Colors.teal),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegisterScreen()),
        );
      },
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      try {
        // Sign in the user
        bool success = await context.read<AuthService>().signIn(
              emailController.text.trim(),
              passwordController.text.trim(),
            );

        // Close loading indicator
        Navigator.of(context).pop();

        if (success) {
          // Clear the text fields
          emailController.clear();
          passwordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login successful')),
          );

          // Get the current user and their role
          final AuthService authService =
              Provider.of<AuthService>(context, listen: false);
          final AppUser? currentUser = authService.currentUser;

          if (currentUser != null) {
            print("Current User Role: ${currentUser.role}"); // Debug print

            // Navigate based on user role
            switch (currentUser.role) {
              case 'driver':
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => DriverScreen()),
                );
                break;
              case 'customer':
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => CustomerScreen()),
                );
                break;
              default:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unknown role: ${currentUser.role}')),
                );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to retrieve user information')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed')),
          );
        }
      } catch (e) {
        // Close loading indicator if it's still showing
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
