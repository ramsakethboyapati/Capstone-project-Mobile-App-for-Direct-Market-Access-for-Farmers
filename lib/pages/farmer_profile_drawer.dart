import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_page.dart';

class FarmerProfileDrawer extends StatelessWidget {
  const FarmerProfileDrawer({super.key});

  Future<Map<String, dynamic>?> _getFarmerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("farmers")
        .doc(user.uid)
        .get();

    if (!doc.exists) return null; // Document deleted
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _getFarmerProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No profile data found"));
          }

          final data = snapshot.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(data["name"] ?? "Unknown"),
                accountEmail: Text(data["email"] ?? ""),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.green),
                ),
                decoration: const BoxDecoration(color: Colors.green),
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(data["phone"] ?? ""),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(data["location"] ?? ""),
              ),
              ListTile(
                leading: const Icon(Icons.grass),
                title: Text("Crops: ${data["crops"] ?? "N/A"}"),
              ),
              const Divider(),

              // Proper Logout
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout"),
                onTap: () async {
                  // Close the drawer first
                  Navigator.of(context).pop();

                  try {
                    // Sign out from Firebase
                    await FirebaseAuth.instance.signOut();

                    // Navigate to WelcomePage and remove all previous routes
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const WelcomePage(),
                      ),
                          (route) => false,
                    );
                  } catch (e) {
                    // Handle errors if sign-out fails
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Logout failed: $e")),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
