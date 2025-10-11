import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSetupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Ensure default admin account exists
  Future<void> ensureAdminExists() async {
    const adminEmail = 'admin@tasksapp.com';
    const adminPassword = 'qwerty';

    try {
      // Try to sign in first to check if it already exists
      await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('✅ Admin already exists.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('⚙️ Admin not found. Creating admin account...');

        // Create new admin account
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        // Store admin details in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'fullName': 'System Admin',
          'email': adminEmail,
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('✅ Admin account created successfully!');
      } else {
        print('⚠️ FirebaseAuth error: ${e.message}');
      }
    } catch (e) {
      print('⚠️ General error during admin setup: $e');
    }
  }
}
