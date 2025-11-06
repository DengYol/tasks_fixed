import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

import '../screens/view_members_page.dart';
import '../screens/ai_assistant_page.dart';
import '../screens/monitor_progress.dart';
import '../screens/edit_profile_page.dart';
import '../screens/logout_screen.dart';
import '../screens/project_page.dart';
import '../screens/assign_task_screen.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  final AuthService authService;

  const AdminDashboard({super.key, required this.authService});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  int _memberCount = 0;
  String? _profileImageUrl; // ✅ admin profile photo

  @override
  void initState() {
    super.initState();
    _fetchMemberCount();
    _fetchAdminProfile();
  }

  Future<void> _fetchMemberCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _memberCount = snapshot.docs.length;
      });
    } catch (e) {
      debugPrint("Error fetching member count: $e");
    }
  }

  /// ✅ Fetch admin profile picture
  Future<void> _fetchAdminProfile() async {
    try {
      final user = widget.authService.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _profileImageUrl = doc.data()?['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching admin profile: $e");
    }
  }

  late final List<Widget> _pages = [
    _buildHomeScreen(),
    ViewMembersPage(authService: widget.authService),
    const MonitorProgress(),
    const ProjectPage(),
    const AssignTasksScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  /// 🔹 HOME SCREEN (Overview of Projects + Tasks)
  Widget _buildHomeScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.deepPurple),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _buildMenuScreenWrapper(context),
                      ),
                    );
                  },
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? const Icon(Icons.person, color: Colors.deepPurple)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              "Welcome, Admin 👋",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Here’s a quick look at ongoing work and deadlines.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIAssistantPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

            const Text(
              "📁 Projects Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            _buildProjectOverview(),

            const SizedBox(height: 25),

            const Text(
              "📝 Tasks Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            _buildTaskOverview(),
          ],
        ),
      ),
    );
  }

  /// ✅ Project Overview
  Widget _buildProjectOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('projects').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        int completed = 0, inProgress = 0, notStarted = 0, dueSoon = 0;
        final now = DateTime.now();

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Not Started';
          final dueDateRaw = data['dueDate'];
          DateTime dueDate = now.add(const Duration(days: 30));

          if (dueDateRaw is Timestamp) {
            dueDate = dueDateRaw.toDate();
          } else if (dueDateRaw is String) {
            dueDate = DateTime.tryParse(dueDateRaw) ?? dueDate;
          }

          if (status == 'Completed') completed++;
          else if (status == 'In Progress') inProgress++;
          else notStarted++;

          if (dueDate.difference(now).inDays <= 3 && status != 'Completed') {
            dueSoon++;
          }
        }

        final total = docs.length;
        final progressPercent = total == 0 ? 0 : ((completed / total) * 100).toInt();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProjectPage()),
            );
          },
          child: _buildOverviewCard(
            "Projects",
            total,
            completed,
            inProgress,
            notStarted,
            progressPercent,
            dueSoon,
          ),
        );
      },
    );
  }

  /// ✅ Task Overview
  Widget _buildTaskOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        int completed = 0, inProgress = 0, pending = 0, dueSoon = 0;
        final now = DateTime.now();

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Pending';
          final dueDateRaw = data['dueDate'];
          DateTime dueDate = now.add(const Duration(days: 30));

          if (dueDateRaw is Timestamp) {
            dueDate = dueDateRaw.toDate();
          } else if (dueDateRaw is String) {
            dueDate = DateTime.tryParse(dueDateRaw) ?? dueDate;
          }

          if (status == 'Completed') completed++;
          else if (status == 'In Progress') inProgress++;
          else pending++;

          if (dueDate.difference(now).inDays <= 3 && status != 'Completed') {
            dueSoon++;
          }
        }

        final total = docs.length;
        final progressPercent = total == 0 ? 0 : ((completed / total) * 100).toInt();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssignTasksScreen()),
            );
          },
          child: _buildOverviewCard(
            "Tasks",
            total,
            completed,
            inProgress,
            pending,
            progressPercent,
            dueSoon,
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(
      String title,
      int total,
      int completed,
      int mid,
      int pending,
      int progressPercent,
      int dueSoon,
      ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total $title: $total", style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text("Completed: $completed, In Progress: $mid, Pending: $pending"),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressPercent / 100,
              color: Colors.deepPurple,
              backgroundColor: Colors.deepPurple.shade100,
            ),
            const SizedBox(height: 8),
            Text(
              "Progress: $progressPercent% • $dueSoon due soon",
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Menu Wrapper
  Widget _buildMenuScreenWrapper(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Menu", style: TextStyle(color: Colors.deepPurple)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
      ),
      body: _buildMenuScreen(),
    );
  }

  /// 🔹 Menu Content
  Widget _buildMenuScreen() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
            backgroundColor: Colors.deepPurple.shade100,
            child: _profileImageUrl == null
                ? const Icon(Icons.person, size: 50, color: Colors.deepPurple)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text("Admin Menu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        const SizedBox(height: 30),
        _buildMenuTile(Icons.edit, "Edit Profile", Colors.blue, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfilePage(authService: widget.authService),
            ),
          );
        }),
        _buildMenuTile(Icons.logout, "Logout", Colors.red, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LogoutScreen(authService: widget.authService),
            ),
          );
        }),
        _buildMenuTile(Icons.help_outline, "Help & Support", Colors.green, () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Help & Support"),
              content: const Text("For any issues or assistance, contact support@tasksApp.co.ke"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        elevation: 10,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.people_alt_outlined),
                if (_memberCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        _memberCount.toString(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: "Members",
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "Progress"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.assignment_turned_in_outlined), label: "Projects"),
          const BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: "Tasks"),
        ],
      ),
    );
  }
}
