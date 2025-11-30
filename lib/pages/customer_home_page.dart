import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'customer_profile_drawer.dart';
import 'cart_page.dart';
import 'customer_orders_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  final _auth = FirebaseAuth.instance;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomerProfileDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,  // 🔹 removes back arrow
        title: const Text("Customer Home"),
        backgroundColor: Colors.green.shade700,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),

      body: _selectedIndex == 0
          ? _buildProductsTab()
          : _selectedIndex == 1
          ? const CartPage()
          : const CustomerOrdersPage(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
        ],
      ),
    );
  }

  // 🔹 Tabs
  Widget _buildProductsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search by crop name...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: "Organic"),
              Tab(text: "Inorganic"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProductsList(true),
                _buildProductsList(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Product List
  Widget _buildProductsList(bool isOrganic) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("products")
          .where("isOrganic", isEqualTo: isOrganic)
          .where("status", isEqualTo: "APPROVED")
          .where("visible", isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var products = snapshot.data!.docs;

        if (_searchQuery.isNotEmpty) {
          products = products
              .where((doc) => (doc["cropName"] ?? "")
              .toString()
              .toLowerCase()
              .contains(_searchQuery))
              .toList();
        }

        if (products.isEmpty) {
          return const Center(child: Text("No products available"));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data();
            final cropName = product["cropName"] ?? "Unknown";
            final cropImage = product["cropImage"] ?? "";
            final price = int.tryParse(product["price"].toString()) ?? 0;
            final quantity = int.tryParse(product["quantity"].toString()) ?? 0;
            final grade = product["grade"] ?? "Pending";

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: cropImage.isNotEmpty
                    ? Image.network(cropImage,
                    width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.agriculture,
                    size: 40, color: Colors.green),
                title: Text(cropName),
                subtitle: Text(
                  "₹$price per kg\nAvailable: $quantity kg\nGrade: $grade",
                ),
                onTap: () =>
                    _showProductDetails(context, product, products[index].id),
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Product Details Popup
  void _showProductDetails(
      BuildContext context, Map<String, dynamic> data, String productId) async {
    String productName = data['cropName'] ?? 'Unknown';
    int productPrice = int.tryParse(data['price'].toString()) ?? 0;
    String farmerId = data['farmerId'] ?? '';
    int availableQty = int.tryParse(data['quantity'].toString()) ?? 0;
    String grade = data['grade'] ?? "Pending";

    String farmerName = "Unknown",
        farmerLocation = "Unknown",
        farmerPhone = "Unknown";

    if (farmerId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection("farmers")
          .doc(farmerId)
          .get();

      if (doc.exists) {
        final fData = doc.data() ?? {};
        farmerName = fData['name'] ?? 'Unknown';
        farmerLocation = fData['location'] ?? 'Unknown';
        farmerPhone = fData['phone'] ?? 'Unknown';
      }
    }

    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(productName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Price: ₹$productPrice per kg"),
                Text("Available: $availableQty kg"),
                Text("Grade: $grade"),
                Text("Farmer: $farmerName"),
                Text("Location: $farmerLocation"),
                GestureDetector(
                  onTap: () async {
                    if (farmerPhone != "Unknown") {
                      final Uri uri = Uri(scheme: 'tel', path: farmerPhone);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: Text(
                    "Phone: $farmerPhone",
                    style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Enter Quantity (kg)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Add to Cart"),
              onPressed: () async {
                final qty = int.tryParse(qtyController.text) ?? 0;

                if (qty < 500) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Minimum order is 500 kg")));
                  return;
                }
                if (qty > availableQty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                      Text("Only $availableQty kg available")));
                  return;
                }

                final customerId = _auth.currentUser!.uid;

                final cartItem = {
                  "productId": productId,
                  "productName": productName,
                  "quantity": qty,
                  "price": productPrice,
                  "totalPrice": productPrice * qty,
                  "farmerId": farmerId,
                  "farmerName": farmerName,
                  "farmerPhone": farmerPhone,
                  "farmerLocation": farmerLocation,
                  "addedAt": FieldValue.serverTimestamp(),
                };

                try {
                  await FirebaseFirestore.instance
                      .collection("carts")
                      .doc(customerId)
                      .collection("items")
                      .add(cartItem);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Added to cart successfully")));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to add: $e")));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
