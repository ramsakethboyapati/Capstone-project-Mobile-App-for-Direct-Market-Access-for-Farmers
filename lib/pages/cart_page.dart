import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _auth = FirebaseAuth.instance;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final customerId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("carts")
            .doc(customerId)
            .collection("items")
            .orderBy("addedAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;
          if (items.isEmpty) {
            return const Center(child: Text("🛒 Your cart is empty"));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index].data();
              final cartDocId = items[index].id;

              final productName = data["productName"] ?? "Unknown";
              final quantity = data["quantity"] ?? 0;
              final price = data["price"] ?? 0;
              final total = data["totalPrice"] ?? 0;
              final farmerId = data["farmerId"] ?? "";

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.shopping_bag, color: Colors.green),
                        title: Text(productName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Quantity: $quantity kg"),
                            Text("Price: ₹$price/kg"),
                            Text("Total: ₹$total"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, customerId, cartDocId),
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text("Buy"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: _isProcessing
                                ? null
                                : () async {
                              setState(() => _isProcessing = true);
                              await _placeOrder(
                                farmerId,
                                customerId,
                                productName,
                                quantity,
                                total,
                                cartDocId,
                              );
                              if (mounted) setState(() => _isProcessing = false);
                            },
                          ),

                          ElevatedButton.icon(
                            icon: const Icon(Icons.handshake),
                            label: const Text("Negotiate"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            onPressed: () {
                              _openNegotiationDialog(
                                context: context,
                                farmerId: farmerId,
                                customerId: customerId,
                                productName: productName,
                                productPricePerKg: price,
                                quantity: quantity,
                                cartDocId: cartDocId,
                              );
                            },
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
      ),
    );
  }

  // --------------------------------------------------------
  // BUY ORDER
  // --------------------------------------------------------
  Future<void> _placeOrder(
      String farmerId,
      String customerId,
      String productName,
      int quantity,
      int totalPrice,
      String cartDocId,
      ) async {
    try {
      final baseOrder = {
        "productName": productName,
        "quantity": quantity,
        "totalPrice": totalPrice,
        "customerId": customerId,
        "farmerId": farmerId,
        "status": "Confirmed",
        "createdAt": FieldValue.serverTimestamp(),
      };

      final custRef = await FirebaseFirestore.instance
          .collection("customers")
          .doc(customerId)
          .collection("orders")
          .add(baseOrder);

      final farmerRef = await FirebaseFirestore.instance
          .collection("farmers")
          .doc(farmerId)
          .collection("orders")
          .add(baseOrder);

      await custRef.update({"farmerOrderId": farmerRef.id});
      await farmerRef.update({"customerOrderId": custRef.id});

      await FirebaseFirestore.instance
          .collection("carts")
          .doc(customerId)
          .collection("items")
          .doc(cartDocId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  // --------------------------------------------------------
  // NEGOTIATION FIXED WITH PROPER DOC IDs
  // --------------------------------------------------------
  void _openNegotiationDialog({
    required BuildContext context,
    required String farmerId,
    required String customerId,
    required String productName,
    required int productPricePerKg,
    required int quantity,
    required String cartDocId,
  }) {
    final offeredPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool _isSending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Negotiate: $productName"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Current price: ₹$productPricePerKg/kg"),
                  const SizedBox(height: 10),
                  TextField(
                    controller: offeredPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Your offer (₹ per kg)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Quantity: $quantity kg"),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    child: const Text("Cancel")
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: _isSending ? null : () async {
                    final offer = int.tryParse(offeredPriceController.text.trim());

                    if (offer == null || offer <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Enter a valid offer amount")),
                      );
                      return;
                    }

                    setDialogState(() => _isSending = true);

                    final negotiationId =
                        FirebaseFirestore.instance.collection("negotiations").doc().id;

                    final negotiationData = {
                      "negotiationId": negotiationId,
                      "productName": productName,
                      "quantity": quantity,
                      "offeredPricePerKg": offer,
                      "offeredTotalPrice": offer * quantity,
                      "customerId": customerId,
                      "farmerId": farmerId,
                      "status": "Pending",
                      "cartItemId": cartDocId,
                      "createdAt": FieldValue.serverTimestamp(),
                    };

                    try {
                      // Global negotiations
                      await FirebaseFirestore.instance
                          .collection("negotiations")
                          .doc(negotiationId)
                          .set(negotiationData);

                      // Farmer negotiations
                      await FirebaseFirestore.instance
                          .collection("farmers")
                          .doc(farmerId)
                          .collection("negotiations")
                          .doc(negotiationId)
                          .set(negotiationData);

                      // Customer negotiations
                      await FirebaseFirestore.instance
                          .collection("customers")
                          .doc(customerId)
                          .collection("negotiations")
                          .doc(negotiationId)
                          .set(negotiationData);

                      // ALSO add as pending order in customer orders page
                      await FirebaseFirestore.instance
                          .collection("customers")
                          .doc(customerId)
                          .collection("orders")
                          .doc(negotiationId)
                          .set({
                        "productName": productName,
                        "quantity": quantity,
                        "totalPrice": offer * quantity,
                        "customerId": customerId,
                        "farmerId": farmerId,
                        "status": "Pending",
                        "createdAt": FieldValue.serverTimestamp(),
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Offer sent to farmer")),
                        );
                      }

                      Navigator.pop(context);

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                      setDialogState(() => _isSending = false);
                    }
                  },
                  child: _isSending
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Send Offer"),
                )
              ],
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------
  // DELETE ITEM
  // --------------------------------------------------------
  void _confirmDelete(BuildContext ctx, String customerId, String cartDocId) {
    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          title: const Text("Remove Item"),
          content: const Text("Remove this item from the cart?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("carts")
                    .doc(customerId)
                    .collection("items")
                    .doc(cartDocId)
                    .delete();

                if (mounted) Navigator.pop(context);
              },
              child: const Text("Delete"),
            )
          ],
        );
      },
    );
  }
}
