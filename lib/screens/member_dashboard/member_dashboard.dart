import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'projects_screen.dart';
import '../logout_screen.dart';
import '../edit_profile_page.dart'; // ✅ Added Edit Profile page import
import '../ai_assistant_page.dart'; // ✅ AI Assistant still used on Home

class MemberDashboard extends StatefulWidget {
  final AuthService authService;

  const MemberDashboard({super.key, required this.authService});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    _buildHomeScreen(), // ✅ Home with AI
    const TasksScreen(),
    const ProjectsScreen(),
    _buildSettingsScreen(), // ✅ Settings with Edit Profile + Logout only
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await widget.authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LogoutScreen(authService: widget.authService),
      ),
    );
  }

  /// ✅ Home Screen (AI Assistant + Quick Overview)
  Widget _buildHomeScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "Welcome, Member",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "How can we assist you today?",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // ✅ AI Assistant Button (kept only on Home)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIAssistantPage()),
                );
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, color: Colors.deepPurple),
                    SizedBox(width: 10),
                    Text(
                      "Ask AI Assistant or Search",
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // ✅ Quick Overview section
            const Text(
              "📋 Quick Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream:
              FirebaseFirestore.instance.collection('tasks').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                int completed = 0, inProgress = 0, pending = 0;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'Pending';
                  if (status == 'Completed') {
                    completed++;
                  } else if (status == 'In Progress') {
                    inProgress++;
                  } else {
                    pending++;
                  }
                }

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Your Task Overview",
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text("✅ Completed: $completed"),
                        Text("⚙️ In Progress: $inProgress"),
                        Text("🕓 Pending: $pending"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Simplified Settings Screen (Edit Profile + Logout only)
  Widget _buildSettingsScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "⚙️ Settings",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.edit, color: Colors.deepPurple),
              title: const Text("Edit Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          EditProfilePage(authService: widget.authService)),
                );
              },
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Projects"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
