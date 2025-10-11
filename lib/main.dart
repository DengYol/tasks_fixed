import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase initialized successfully");

    // Safe delay so Flutter UI loads before admin check
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _createAdminIfNotExists();
    });

    runApp(const MyApp());
  } catch (e) {
    debugPrint("🔥 Firebase init failed: $e");
    runApp(const ErrorApp());
  }
}

Future<void> _createAdminIfNotExists() async {
  const adminEmail = 'admin@tasksapp.com';
  const adminPassword = 'admin123';

  try {
    final existingAdmin = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: adminEmail)
        .limit(1)
        .get();

    if (existingAdmin.docs.isEmpty) {
      try {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': adminEmail,
          'userType': 'admin', // ✅ use userType for consistency
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Default admin account created successfully.');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          debugPrint('ℹ️ Admin already exists.');
        } else {
          debugPrint('⚠️ Failed to create admin: ${e.message}');
        }
      }
    } else {
      debugPrint('ℹ️ Admin already exists in Firestore.');
    }
  } catch (e) {
    debugPrint('🔥 Error checking/creating admin: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tasks App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: LoginScreen(authService: authService),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Text(
            "🔥 Firebase failed to initialize.\nCheck google-services.json setup.",
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
