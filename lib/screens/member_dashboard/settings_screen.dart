import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../logout_screen.dart';
import '../edit_profile_page.dart';

class SettingsScreen extends StatelessWidget {
  final AuthService authService;

  const SettingsScreen({super.key, required this.authService});

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    Color? iconColor,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.purple),
        title: Text(title,
            style: TextStyle(
              color: iconColor ?? Colors.black,
              fontWeight: FontWeight.w600,
            )),
        trailing: showArrow ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar to match other screens
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 24),
            const Text(
              "Settings",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 24),

            // Edit Profile
            _buildCard(
              context: context,
              icon: Icons.edit,
              title: "Edit Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfilePage(authService: authService),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Account Settings (Placeholder)
            _buildCard(
              context: context,
              icon: Icons.settings,
              title: "Account Settings",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Account Settings coming soon")),
                );
              },
            ),

            const SizedBox(height: 12),

            // Notifications (Placeholder)
            _buildCard(
              context: context,
              icon: Icons.notifications,
              title: "Notifications",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Notifications settings coming soon")),
                );
              },
            ),

            const SizedBox(height: 12),

            // Logout
            _buildCard(
              context: context,
              icon: Icons.logout,
              iconColor: Colors.red,
              title: "Logout",
              showArrow: false,
              onTap: () async {
                await authService.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LogoutScreen(authService: authService),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
