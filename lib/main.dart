import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart'; // ✅ Admin interface
import 'screens/member_dashboard/member_dashboard.dart'; // ✅ Member interface
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase initialized successfully");

    // Create default admin if not found
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
          'userType': 'admin',
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 3,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.deepPurple,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // ⏳ Show loading spinner while checking login state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 🔒 If not logged in, go to LoginScreen
          if (!snapshot.hasData) {
            return LoginScreen(authService: authService);
          }

          // ✅ If logged in, check user type from Firestore
          final user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const Scaffold(
                  body: Center(
                    child: Text("⚠️ User record not found in Firestore"),
                  ),
                );
              }

              final userType = userSnapshot.data!.get('userType');

              // 🧭 Route user based on type
              if (userType == 'admin') {
                return AdminDashboard(authService: authService);
              } else {
                return MemberDashboard(authService: authService); // ✅ fixed
              }
            },
          );
        },
      ),
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
