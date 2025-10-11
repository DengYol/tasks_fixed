import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  final AuthService authService;

  const AdminDashboard({super.key, required this.authService});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int memberCount = 0;
  int pendingTasks = 0;
  int completedTasks = 0;
  List<String> recentActivities = [];

  // Controllers for assigning a task
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final assignedToController = TextEditingController();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      _buildDashboardPage(),
      _buildMembersPage(),
      _buildAssignTaskPage(),
      _buildReportsPage(),
      _buildSettingsPage(),
    ]);

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final usersSnapshot =
    await _firestore.collection('users').where('role', isEqualTo: 'member').get();
    final tasksSnapshot = await _firestore.collection('tasks').get();

    int pending = tasksSnapshot.docs
        .where((task) => task['status'] == 'Pending')
        .length;
    int completed = tasksSnapshot.docs
        .where((task) => task['status'] == 'Completed')
        .length;

    setState(() {
      memberCount = usersSnapshot.size;
      pendingTasks = pending;
      completedTasks = completed;
      recentActivities = tasksSnapshot.docs
          .take(3)
          .map((task) => "Task '${task['title']}' assigned to ${task['assignedTo']}")
          .toList();
    });
  }

  Future<void> _assignTask() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        assignedToController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    await _firestore.collection('tasks').add({
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'assignedTo': assignedToController.text.trim(),
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Task assigned successfully")),
    );

    setState(() {
      recentActivities.insert(0,
          "Task '${titleController.text.trim()}' assigned to ${assignedToController.text.trim()}");
      pendingTasks++;
    });

    titleController.clear();
    descriptionController.clear();
    assignedToController.clear();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await widget.authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(authService: widget.authService)),
    );
  }

  // ---------------------- PAGES ----------------------
  Widget _buildDashboardPage() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome back, Admin 👋",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Here's an overview of your workspace today.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Dashboard stats
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard("Total Members", "$memberCount",
                    Icons.group, Colors.deepPurple),
                _buildStatCard("Pending Tasks", "$pendingTasks",
                    Icons.pending_actions, Colors.orange),
                _buildStatCard("Completed", "$completedTasks",
                    Icons.check_circle, Colors.green),
                _buildStatCard("Reports", "5", Icons.bar_chart, Colors.blue),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              "Recent Activities",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (recentActivities.isEmpty)
              const Text("No recent activities found.")
            else
              for (var act in recentActivities) _buildActivityItem(act),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('role', isEqualTo: 'member').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final members = snapshot.data!.docs;
        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.deepPurple),
                title: Text(member['fullName']),
                subtitle: Text(member['email']),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAssignTaskPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            "📝 Assign New Task",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: "Task Title",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: "Task Description",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: assignedToController,
            decoration: const InputDecoration(
              labelText: "Assign To (member email)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _assignTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Assign Task"),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsPage() => const Center(
    child: Text(
      "📊 Reports & Analytics Coming Soon",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    ),
  );

  Widget _buildSettingsPage() => const Center(
    child: Text(
      "⚙️ Settings Page Coming Soon",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    ),
  );

  // ---------------------- HELPERS ----------------------
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: const Icon(Icons.bolt, color: Colors.deepPurple),
        title: Text(text),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  void _onProfileMenuSelected(String choice) {
    switch (choice) {
      case 'Profile':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile tapped!")),
        );
        break;
      case 'Settings':
        setState(() => _selectedIndex = 4); // Go to Settings tab
        break;
      case 'Logout':
        _logout();
        break;
    }
  }

  // ---------------------- MAIN UI ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.task_alt, color: Colors.deepPurple, size: 26),
            SizedBox(width: 8),
            Text(
              "TASKS Admin",
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.deepPurple),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notifications tapped!")),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.deepPurple),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: _onProfileMenuSelected,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'Profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.deepPurple),
                    SizedBox(width: 10),
                    Text("View Profile"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: Colors.deepPurple),
                    SizedBox(width: 10),
                    Text("Settings"),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'Logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Members'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Assign'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
