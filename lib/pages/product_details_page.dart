import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;
  final String farmerId;
  final String productName;
  final int pricePerKg;
  final String imageUrl;

  const ProductDetailsPage({
    super.key,
    required this.productId,
    required this.farmerId,
    required this.productName,
    required this.pricePerKg,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final quantityController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            imageUrl.isNotEmpty
                ? Image.network(imageUrl, height: 200)
                : const Icon(Icons.agriculture, size: 100, color: Colors.green),
            const SizedBox(height: 16),
            Text("Price: ₹$pricePerKg per kg",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Quantity (kg)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text("Add to Cart"),
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () async {
                    final qty = int.tryParse(quantityController.text);
                    if (qty == null || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invalid quantity")));
                      return;
                    }

                    final totalPrice = qty * pricePerKg;

                    await FirebaseFirestore.instance
                        .collection("customers")
                        .doc(userId)
                        .collection("cart")
                        .add({
                      "productId": productId,
                      "farmerId": farmerId,
                      "productName": productName,
                      "quantity": qty,
                      "pricePerKg": pricePerKg,
                      "totalPrice": totalPrice,
                      "createdAt": FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Added to cart successfully")));
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text("Buy Now"),
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    final qty = int.tryParse(quantityController.text);
                    if (qty == null || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invalid quantity")));
                      return;
                    }

                    final totalPrice = qty * pricePerKg;
                    final orderData = {
                      "productName": productName,
                      "quantity": qty,
                      "totalPrice": totalPrice,
                      "customerId": userId,
                      "farmerId": farmerId,
                      "status": "Confirmed",
                      "createdAt": FieldValue.serverTimestamp(),
                    };

                    await FirebaseFirestore.instance
                        .collection("customers")
                        .doc(userId)
                        .collection("orders")
                        .add(orderData);

                    await FirebaseFirestore.instance
                        .collection("farmers")
                        .doc(farmerId)
                        .collection("orders")
                        .add(orderData);

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Order placed successfully")));
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
