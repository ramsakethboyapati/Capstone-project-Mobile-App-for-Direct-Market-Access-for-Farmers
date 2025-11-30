import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FarmerNegotiationsPage extends StatefulWidget {
  final String farmerId;
  const FarmerNegotiationsPage({Key? key, required this.farmerId}) : super(key: key);

  @override
  State<FarmerNegotiationsPage> createState() => _FarmerNegotiationsPageState();
}

class _FarmerNegotiationsPageState extends State<FarmerNegotiationsPage> {
  bool _isProcessing = false; // Prevent multiple taps

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Negotiations"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("farmers")
            .doc(widget.farmerId)
            .collection("negotiations")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No negotiations yet"));
          }

          final negotiations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: negotiations.length,
            itemBuilder: (context, index) {
              final data = negotiations[index].data() as Map<String, dynamic>;
              final docId = negotiations[index].id;

              final product = data["productName"] ?? "Unknown";
              final price = data["offeredPricePerKg"] ?? 0;     // ✅ FIXED
              final qty = data["quantity"] ?? 0;
              final status = data["status"] ?? "Pending";
              final date = data["createdAt"] != null
                  ? DateFormat('dd MMM, hh:mm a')
                  .format((data["createdAt"] as Timestamp).toDate())
                  : "Unknown";

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("$product - ₹$price/kg"),
                  subtitle: Text("Qty: $qty kg\nDate: $date\nStatus: $status"),
                  trailing: status == "Pending"
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: _isProcessing
                            ? null
                            : () async {
                          setState(() => _isProcessing = true);
                          await _updateNegotiationStatus(
                              docId, "Confirmed", data);
                          setState(() => _isProcessing = false);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _isProcessing
                            ? null
                            : () async {
                          setState(() => _isProcessing = true);
                          await _updateNegotiationStatus(
                              docId, "Rejected", data);
                          setState(() => _isProcessing = false);
                        },
                      ),
                    ],
                  )
                      : Text(
                    status,
                    style: TextStyle(
                      color: status == "Confirmed"
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateNegotiationStatus(
      String negotiationId, String newStatus, Map<String, dynamic> data) async {
    try {
      // 1️⃣ Update negotiation status in farmer's collection
      final farmerNegotiationRef = FirebaseFirestore.instance
          .collection("farmers")
          .doc(widget.farmerId)
          .collection("negotiations")
          .doc(negotiationId);

      await farmerNegotiationRef.update({"status": newStatus});

      // 2️⃣ Add to farmer orders
      final farmerOrdersRef = FirebaseFirestore.instance
          .collection("farmers")
          .doc(widget.farmerId)
          .collection("orders");

      await farmerOrdersRef.add({
        "productName": data["productName"],
        "quantity": data["quantity"],

        // ✅ FIXED (no more null crash)
        "totalPrice": data["offeredTotalPrice"] ??
            (data["offeredPricePerKg"] * data["quantity"]),

        "customerId": data["customerId"],
        "farmerId": widget.farmerId,
        "status": newStatus,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 3️⃣ Update corresponding customer orders (Pending → Confirmed/Rejected)
      final customerOrders = await FirebaseFirestore.instance
          .collection("customers")
          .doc(data["customerId"])
          .collection("orders")
          .where("productName", isEqualTo: data["productName"])
          .where("status", isEqualTo: "Pending")
          .get();

      for (var doc in customerOrders.docs) {
        await doc.reference.update({"status": newStatus});
      }

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Offer $newStatus successfully")),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        });
      }
    }
  }
}
