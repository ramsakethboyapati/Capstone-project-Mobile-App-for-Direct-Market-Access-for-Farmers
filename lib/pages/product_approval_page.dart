import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductApprovalPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductApprovalPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<ProductApprovalPage> createState() => _ProductApprovalPageState();
}

class _ProductApprovalPageState extends State<ProductApprovalPage> {
  String selectedGrade = "A";
  bool isLoading = false;

  Future<void> approveProduct() async {
    setState(() => isLoading = true);

    await FirebaseFirestore.instance
        .collection("products")
        .doc(widget.productId)
        .update({
      "grade": selectedGrade,
      "adminGrade": selectedGrade,  // ⭐ REQUIRED FIX
      "status": "APPROVED",
      "visible": true,
    });

    setState(() => isLoading = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product Approved!")),
    );
  }

  Future<void> rejectProduct() async {
    setState(() => isLoading = true);

    await FirebaseFirestore.instance
        .collection("products")
        .doc(widget.productId)
        .update({
      "status": "REJECTED",
      "visible": false,
    });

    setState(() => isLoading = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product Rejected!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.productData;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Product"),
        backgroundColor: Colors.green,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Crop Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                data["cropImage"],
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            // Crop Name
            Text(
              data["cropName"],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Details
            Text("Quantity: ${data["quantity"]} kg",
                style: const TextStyle(fontSize: 16)),
            Text("Price: ₹${data["price"]}/kg",
                style: const TextStyle(fontSize: 16)),
            Text("Organic: ${data["isOrganic"] ? "Yes" : "No"}",
                style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 20),

            // Grade Dropdown
            DropdownButtonFormField<String>(
              value: selectedGrade,
              items: ["A", "B", "C"]
                  .map((grade) =>
                  DropdownMenuItem(value: grade, child: Text(grade)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedGrade = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Select Grade",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            // Approve / Reject Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: rejectProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(120, 45),
                  ),
                  child: const Text("Reject"),
                ),
                ElevatedButton(
                  onPressed: approveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(120, 45),
                  ),
                  child: const Text("Approve"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
