import 'package:flutter/material.dart';
import '../auth/auth_service.dart';

import 'customer_home_page.dart';

class CustomerLoginPage extends StatelessWidget {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  CustomerLoginPage({super.key});

  Future<void> _onLogin(BuildContext context) async {
    final err = await _auth.login(
      email: _email.text.trim(),
      password: _password.text.trim(),
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
      appBar: AppBar(title: const Text("Customer Login")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 16),
            TextField(controller: _password, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => _onLogin(context), child: const Text("Login")),
          ],
        ),
      ),
    );
  }
}
