import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_page.dart'; // 👈 import WelcomePage

class CustomerProfileDrawer extends StatelessWidget {
  const CustomerProfileDrawer({super.key});

  Future<Map<String, dynamic>?> _getCustomerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('customers') // 👈 use customers collection
        .doc(user.uid)
        .get();

    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _getCustomerProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No profile data found"));
          }

          final data = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.green.shade700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 40, color: Colors.green),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data["name"] ?? "Customer",
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18),
                    ),
                    Text(
                      data["email"] ?? "",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Extra info
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text("Phone: ${data["phone"] ?? ""}"),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: Text("Address: ${data["address"] ?? ""}"),
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();

                  // 👇 Clear stack and go to WelcomePage
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomePage()),
                        (route) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
