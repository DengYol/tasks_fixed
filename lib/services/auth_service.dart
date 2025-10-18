import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Register user (with optional userType)
  Future<User?> registerWithEmail(
      String email,
      String password, {
        String userType = 'member',
      }) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // 🔹 Login existing user
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // 🔹 Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 🔹 Stream user changes (for live login/logout state)
  Stream<User?> get userChanges => _auth.authStateChanges();

  // 🔹 Get current logged-in user
  User? get currentUser => _auth.currentUser;
}
