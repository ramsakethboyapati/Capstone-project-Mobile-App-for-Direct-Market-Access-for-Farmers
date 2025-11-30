import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ---------------- SIGN UP ----------------
  Future<String?> signUp({
    required String email,
    required String password,
    required String role, // "customer" or "farmer"
    required Map<String, dynamic> profile,
  }) async {
    try {
      // Create user in Firebase Authentication
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user profile in Firestore
      await _db
          .collection(role == "farmer" ? "farmers" : "customers")
          .doc(cred.user!.uid)
          .set({
        "uid": cred.user!.uid,
        "email": email,
        "role": role,
        "createdAt": FieldValue.serverTimestamp(),
        ...profile,
      });

      return null; // ✅ success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Something went wrong. Please try again.";
    }
  }

  /// ---------------- LOGIN ----------------
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // ✅ success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Login failed. Please try again.";
    }
  }

  /// ---------------- LOGOUT ----------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// ---------------- AUTH STREAM ----------------
  Stream<User?> get authStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// ---------------- GET PROFILE ----------------
  Future<Map<String, dynamic>?> getProfile({required String role}) async {
    if (currentUser == null) return null;
    final doc =
    await _db.collection(role == "farmer" ? "farmers" : "customers").doc(currentUser!.uid).get();
    return doc.data();
  }
}
