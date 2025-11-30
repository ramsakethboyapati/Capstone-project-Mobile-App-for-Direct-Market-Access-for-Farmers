import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentPage extends StatefulWidget {
  final DocumentReference orderRef;
  final int amount;

  const PaymentPage({super.key, required this.orderRef, required this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _startPayment() {
    final user = FirebaseAuth.instance.currentUser;

    final options = {
      'key': 'rzp_test_RjtvCUmorVYP5L',
      'amount': widget.amount * 100,
      'name': 'Agri Direct',
      'description': 'Order Payment',
      'prefill': {
        'contact': user?.phoneNumber ?? "",
        'email': user?.email ?? "",
      },
      'theme': {'color': '#00A86B'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse r) async {
    try {
      final snap = await widget.orderRef.get();
      final data = snap.data() as Map<String, dynamic>;

      final farmerId = data["farmerId"];
      final farmerOrderId = data["farmerOrderId"];

      // Update CUSTOMER order
      await widget.orderRef.update({
        "status": "Paid",
        "paymentId": r.paymentId,
        "paidAt": FieldValue.serverTimestamp(),
      });

      // Update FARMER order
      final farmerOrderRef = FirebaseFirestore.instance
          .collection("farmers")
          .doc(farmerId)
          .collection("orders")
          .doc(farmerOrderId);

      await farmerOrderRef.update({
        "status": "Paid",
        "paymentId": r.paymentId,
        "paidAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Payment Successful!")));
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("DB update failed: $e")));
    }
  }

  void _handlePaymentError(PaymentFailureResponse r) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Payment failed")));
  }

  void _handleExternalWallet(ExternalWalletResponse r) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Wallet: ${r.walletName}")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pay Now"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Amount: ₹${widget.amount}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                setState(() => _isProcessing = true);
                _startPayment();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Pay"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            )
          ],
        ),
      ),
    );
  }
}
