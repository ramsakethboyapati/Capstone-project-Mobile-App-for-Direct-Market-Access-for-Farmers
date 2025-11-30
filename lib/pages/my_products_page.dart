import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class MyProductsPage extends StatelessWidget {
  const MyProductsPage({super.key});

  Future<void> _deleteProduct(BuildContext context, String docId, String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty && imageUrl.startsWith("http")) {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
      }

      await FirebaseFirestore.instance.collection("products").doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete product: $e")),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, String docId, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteProduct(context, docId, imageUrl);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("My Products")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("products")
            .where("farmerId", isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No products added yet"));
          }

          final products = snapshot.data!.docs.toList();
          products.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            return bTime?.compareTo(aTime ?? Timestamp(0, 0)) ?? 0;
          });

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final product = doc.data() as Map<String, dynamic>;

              final docId = doc.id;
              final cropName = product["cropName"] ?? "Unknown";
              final cropImage = product["cropImage"] ?? "";
              final quantity = product["quantity"]?.toString() ?? "0";
              final price = product["price"]?.toString() ?? "0";
              final isOrganic = product["isOrganic"] ?? false;
              final grade = product["grade"] ?? "N/A";

              final status = product["status"] ?? "PENDING";

              // ⭐ NEW STATUS LOGIC
              String statusText = "Pending Approval";
              Color statusColor = Colors.orange;

              if (status == "APPROVED" && grade != "N/A") {
                statusText = "Grade Given ($grade)";
                statusColor = Colors.green;
              } else if (status == "REJECTED") {
                statusText = "Rejected";
                statusColor = Colors.red;
              }

              final harvestDate = product["harvestDate"];
              String formattedHarvest = "Not set";
              if (harvestDate != null && harvestDate is Timestamp) {
                formattedHarvest =
                    DateFormat("yyyy-MM-dd").format(harvestDate.toDate());
              }

              final createdAt = product["createdAt"];
              String formattedCreated = "Unknown";
              if (createdAt != null && createdAt is Timestamp) {
                formattedCreated =
                    DateFormat("yyyy-MM-dd HH:mm").format(createdAt.toDate());
              }

              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cropImage.isNotEmpty && cropImage.startsWith("http"))
                        Image.network(cropImage, height: 100, fit: BoxFit.cover)
                      else if (cropImage.isNotEmpty)
                        Image.asset(cropImage, height: 100, fit: BoxFit.cover)
                      else
                        Image.asset("assets/images/placeholder.png",
                            height: 100, fit: BoxFit.cover),

                      const SizedBox(height: 10),

                      // ⭐ STATUS BADGE (NEW)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        cropName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Quantity: $quantity kg"),
                      Text("Price: ₹$price per kg"),
                      Text("Organic: ${isOrganic ? "Yes" : "No"}"),
                      Text("Grade: $grade"),
                      Text("Harvest Date: $formattedHarvest"),
                      Text("Added On: $formattedCreated"),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showDeleteDialog(context, docId, cropImage),
                          icon: const Icon(Icons.delete),
                          label: const Text("Delete"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
