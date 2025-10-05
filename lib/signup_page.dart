// lib/signup_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    // 1. Basic empty field validation (already exists)
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _usernameController.text.isEmpty || _mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    // --- NEW VALIDATION LOGIC ADDED HERE ---

    // 2. Mobile number validation (must be 10 digits)
    final mobileNumber = _mobileController.text;
    if (mobileNumber.length != 10 || int.tryParse(mobileNumber) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number must be exactly 10 digits'), backgroundColor: Colors.red),
      );
      return;
    }

    // 3. Strong password validation
    final password = _passwordController.text;
    String passwordPattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    RegExp passwordRegExp = RegExp(passwordPattern);
    if (!passwordRegExp.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be 8+ chars, with uppercase, number & special char'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // --- END OF NEW VALIDATION ---

    setState(() {
      _isLoading = true;
    });

    // ### THIS IS THE CHANGED LINE FOR WINDOWS ###
    const String apiUrl = 'http://10.112.13.230:8000/signup';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "fullName": _nameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
          "username": _usernameController.text,
          "mobile": _mobileController.text
        }),
      );

      if (mounted) {
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup Successful! Please login.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Go back to the login page
        } else {
          final responseBody = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signup Failed: ${responseBody['detail']}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not connect to the server.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset('assets/images/OIP.jpeg', fit: BoxFit.cover, color: Colors.black.withOpacity(0.5), colorBlendMode: BlendMode.darken),
          Positioned(top: 40.0, left: 10.0, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                color: Colors.white.withOpacity(0.85),
                elevation: 8.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green[800])),
                      const SizedBox(height: 20),
                      TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.account_circle), border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextFormField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()), obscureText: true),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), textStyle: const TextStyle(fontSize: 18)),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}