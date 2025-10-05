// lib/main.dart

import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the login page we created

void main() {
  runApp(const FarmerApp());
}

class FarmerApp extends StatelessWidget {
  const FarmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmer App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      // Set the LoginPage as the first screen
      home: const LoginPage(),
    );
  }
}