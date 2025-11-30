import 'package:flutter/material.dart';
import '../auth/auth_service.dart';

import 'farmer_home_page.dart';

class FarmerSignUpPage extends StatelessWidget {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _crops = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  FarmerSignUpPage({super.key});

  Future<void> _onSignUp(BuildContext context) async {
    final err = await _auth.signUp(
      email: _email.text.trim(),
      password: _password.text.trim(),
      role: "farmer",
      profile: {
        "name": _name.text.trim(),
        "phone": _phone.text.trim(),
        "location": _location.text.trim(),
        "crops": _crops.text.trim(),
      },
    );
    if (err == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FarmerHomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Farmer Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _name, decoration: const InputDecoration(labelText: "Farmer Name")),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
              TextField(controller: _location, decoration: const InputDecoration(labelText: "Farm Location")),
              TextField(controller: _crops, decoration: const InputDecoration(labelText: "Crops Grown")),
              TextField(controller: _email, decoration: const InputDecoration(labelText: "Email"), keyboardType: TextInputType.emailAddress),
              TextField(controller: _password, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _onSignUp(context),
                child: const Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
