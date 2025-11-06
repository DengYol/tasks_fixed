import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Register user (with optional userType)
  Future<User?> registerWithEmail(
      String email,
      String password, {
        String userType = 'member',
      }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) throw Exception("User creation failed.");

      // ✅ Save user data to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ User registered: $email ($userType)");
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("⚠️ FirebaseAuthException during registration: ${e.code}");
      return null;
    } catch (e) {
      debugPrint("🔥 Unknown error during registration: $e");
      return null;
    }
  }

  /// 🔹 Login existing user
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint("✅ User logged in: $email");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("⚠️ FirebaseAuthException during login: ${e.code}");
      return null;
    } catch (e) {
      debugPrint("🔥 Unknown login error: $e");
      return null;
    }
  }

  /// 🔹 Sign out user (standard Firebase naming)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint("👋 User signed out successfully.");
    } catch (e) {
      debugPrint("⚠️ Sign-out error: $e");
    }
  }

  /// 🔹 Stream user changes (for live login/logout state)
  Stream<User?> get userChanges => _auth.authStateChanges();

  /// 🔹 Get current logged-in user
  User? get currentUser => _auth.currentUser;
}
