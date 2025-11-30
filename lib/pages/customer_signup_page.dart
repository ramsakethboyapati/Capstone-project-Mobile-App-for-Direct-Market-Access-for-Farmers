import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_service.dart';

import 'customer_home_page.dart';

class CustomerSignUpPage extends StatelessWidget {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  CustomerSignUpPage({super.key});

  Future<void> _onSignUp(BuildContext context) async {
    final err = await _auth.signUp(
      email: _email.text.trim(),
      password: _password.text.trim(),
      role: "customer",
      profile: {
        "name": _name.text.trim(),
        "phone": _phone.text.trim(),
        "address": _address.text.trim(),
      },
    );
    if (err == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _name, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone),
              TextField(controller: _address, decoration: const InputDecoration(labelText: "Delivery Address")),
              TextField(controller: _email, decoration: const InputDecoration(labelText: "Email"), keyboardType: TextInputType.emailAddress),
              TextField(controller: _password, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => _onSignUp(context), child: const Text("Sign Up")),
            ],
          ),
        ),
      ),
    );
  }
}
