import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class FarmerOrdersPage extends StatelessWidget {
  final String farmerId;
  const FarmerOrdersPage({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Paid Orders"),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("farmers")
            .doc(farmerId)
            .collection("orders")
            .where("status", isEqualTo: "Paid")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No paid orders yet"));
          }

          final orderDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orderDocs.length,
            itemBuilder: (context, index) {
              final order = orderDocs[index];
              final data = order.data() as Map<String, dynamic>;

              final product = data["productName"] ?? "Unknown";
              final quantity = data["quantity"] ?? 0;
              final total = data["totalPrice"] ?? 0;
              final status = data["status"] ?? "";
              final customerId = data["customerId"] ?? "";

              final createdAt = data["createdAt"] != null
                  ? DateFormat('dd MMM yyyy, hh:mm a')
                  .format((data["createdAt"] as Timestamp).toDate())
                  : "Unknown Date";

              // ⭐ Updated Fetch: Search by uid instead of doc()
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection("customers")
                    .where("uid", isEqualTo: customerId)
                    .limit(1)
                    .get(),

                builder: (context, customerSnapshot) {
                  String customerName = "Unknown";
                  String customerPhone = "Unknown";

                  if (customerSnapshot.hasData &&
                      customerSnapshot.data!.docs.isNotEmpty) {
                    final cData = customerSnapshot.data!.docs.first.data()
                    as Map<String, dynamic>;

                    customerName = cData["name"] ?? "Unknown";
                    customerPhone = cData["phone"] ?? "Unknown";
                  }

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),

                          const SizedBox(height: 6),
                          Text("Quantity: $quantity kg"),
                          Text("Total Price: ₹$total"),
                          Text("Order Date: $createdAt"),

                          const SizedBox(height: 10),

                          Text("Customer: $customerName"),

                          const SizedBox(height: 4),

                          GestureDetector(
                            onTap: () async {
                              if (customerPhone == "Unknown") return;

                              final uri =
                              Uri(scheme: 'tel', path: customerPhone);

                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Text(
                              "Phone: $customerPhone",
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Chip(
                                label: Text(
                                  status,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            ],
                          )
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
