import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddProductPage extends StatefulWidget {
  final String cropName;
  final String cropImage;

  const AddProductPage({
    super.key,
    required this.cropName,
    required this.cropImage,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isOrganic = false;
  DateTime? _harvestDate;
  File? _pickedImage;

  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _harvestDate = picked;
      });
    }
  }

  Future<void> _saveProduct() async {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product image")),
      );
      return;
    }

    if (_quantityController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantity and Price cannot be empty")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("product_images")
          .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

      await storageRef.putFile(_pickedImage!);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection("products").add({
        "farmerId": user.uid,
        "cropName": widget.cropName,
        "cropImage": imageUrl,
        "quantity": _quantityController.text.trim(),
        "price": _priceController.text.trim(),
        "isOrganic": _isOrganic,
        "harvestDate":
        _harvestDate != null ? Timestamp.fromDate(_harvestDate!) : null,
        "createdAt": FieldValue.serverTimestamp(),

        // ⭐ NEW LOGIC ⭐
        "grade": null,            // Farmer cannot give grade
        "status": "PENDING",      // Admin must approve
        "visible": false,         // Not visible to customer until admin approves
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added successfully!")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add product: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add ${widget.cropName}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: _pickedImage != null
                    ? Image.file(_pickedImage!, height: 120, fit: BoxFit.cover)
                    : Container(
                  height: 120,
                  width: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.camera_alt, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: "Quantity (kg)"),
              keyboardType: TextInputType.number,
            ),

            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Price (₹/kg)"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            SwitchListTile(
              title: const Text("Organic"),
              value: _isOrganic,
              onChanged: (val) {
                setState(() {
                  _isOrganic = val;
                });
              },
            ),

            // ⭐ Removed Grade Dropdown ⭐

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _harvestDate == null
                        ? "No harvest date selected"
                        : "Harvest Date: ${DateFormat('yyyy-MM-dd').format(_harvestDate!)}",
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text("Select Date"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _saveProduct,
                child: const Text("Save Product"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
