import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class LogoutScreen extends StatelessWidget {
  final AuthService authService;

  const LogoutScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    // Perform logout immediately when this screen is built
    Future.microtask(() async {
      await authService.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(authService: authService),
        ),
      );
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // show briefly while logging out
      ),
    );
  }
}
