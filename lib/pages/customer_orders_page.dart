import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_page.dart';

class CustomerOrdersPage extends StatelessWidget {
  const CustomerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final customerId = FirebaseAuth.instance.currentUser?.uid;
    if (customerId == null) {
      return const Center(child: Text("Not logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("customers")
            .doc(customerId)
            .collection("orders")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!.docs;
          if (orders.isEmpty) {
            return const Center(child: Text("No orders yet"));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final product = data["productName"] ?? "Unknown";
              final qty = data["quantity"] ?? 0;
              final total = data["totalPrice"] ?? 0;
              final status = data["status"] ?? "Pending";
              final farmerId = data["farmerId"] ?? "";
              final date = data["createdAt"] != null
                  ? DateFormat('dd MMM, hh:mm a')
                  .format((data["createdAt"] as Timestamp).toDate())
                  : "Unknown";

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("farmers")
                    .doc(farmerId)
                    .get(),
                builder: (context, farmerSnapshot) {
                  String farmerName = "Unknown";
                  String farmerPhone = "Unknown";
                  String farmerLocation = "Unknown";

                  if (farmerSnapshot.hasData &&
                      farmerSnapshot.data!.exists) {
                    final fData =
                    farmerSnapshot.data!.data() as Map<String, dynamic>;
                    farmerName = fData["name"] ?? "Unknown";
                    farmerPhone = fData["phone"] ?? "Unknown";
                    farmerLocation = fData["location"] ?? "Unknown";
                  }

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              product,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                            Text("Quantity: $qty kg\nDate: $date"),

                            // ⭐⭐⭐ ONLY THIS PART IS UPDATED ⭐⭐⭐
                            trailing: status == "Confirmed"
                                ? ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentPage(
                                      orderRef:
                                      orders[index].reference,
                                      amount: int.tryParse(
                                          total.toString()) ??
                                          0,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: const Text("Confirm"),
                            )
                                : Chip(
                              label: Text(
                                status,
                                style: const TextStyle(
                                    color: Colors.white),
                              ),
                              backgroundColor:
                              status == "Rejected"
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text("Total Price: ₹$total"),
                          const SizedBox(height: 5),
                          Text("Farmer: $farmerName"),
                          Text("Location: $farmerLocation"),
                          GestureDetector(
                            onTap: () async {
                              if (farmerPhone != "Unknown") {
                                final Uri uri =
                                Uri(scheme: 'tel', path: farmerPhone);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              }
                            },
                            child: Text("Phone: $farmerPhone",
                                style: const TextStyle(
                                    color: Colors.blue,
                                    decoration:
                                    TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
