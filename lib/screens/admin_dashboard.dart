import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'manage_tasks_page.dart';
import 'view_members_page.dart';
import 'login_screen.dart';
import 'edit_profile_page.dart';
import 'ai_assistant_page.dart'; // 👈 AI Assistant screen

class AdminDashboard extends StatefulWidget {
  final AuthService authService;

  const AdminDashboard({super.key, required this.authService});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _profileImageUrl;
  String? selectedMember;
  bool assignToAll = false;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildDashboardPage(),
      ViewMembersPage(authService: widget.authService),
      _buildAssignTaskPage(),
      ManageTasksPage(),
      _buildReportsPage(),
    ];
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final docSnap = await _firestore.collection('users').doc(user.uid).get();
      final data = docSnap.data() as Map<String, dynamic>? ?? {};
      setState(() {
        _profileImageUrl = data['profileImage'] as String?;
      });
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  /// 🔔 CHECK IF THERE ARE UNREAD SUBMISSIONS
  Stream<int> _unreadSubmissionsCount() {
    return _firestore
        .collection('submissions')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 🔔 SHOW SUBMITTED WORKS
  Future<void> _showSubmissionsDialog() async {
    final submissions = await _firestore
        .collection('submissions')
        .orderBy('submittedAt', descending: true)
        .get();

    if (submissions.docs.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("No Submissions"),
          content: Text("No work has been submitted yet."),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("📥 Submitted Work"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: submissions.docs.length,
            itemBuilder: (context, index) {
              final data = submissions.docs[index].data();
              final title = data['taskTitle'] ?? 'Untitled';
              final memberName = data['memberName'] ?? 'Unknown';
              final submittedAt =
                  data['submittedAt']?.toDate() ?? DateTime.now();
              final status = data['status'] ?? 'Pending';

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in,
                      color: Colors.deepPurple),
                  title: Text(title),
                  subtitle: Text(
                    "By: $memberName\nStatus: $status\n${submittedAt.toLocal()}",
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // mark all as read
              final batch = _firestore.batch();
              for (var doc in submissions.docs) {
                batch.update(doc.reference, {'isRead': true});
              }
              await batch.commit();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Mark All as Read"),
          ),
        ],
      ),
    );
  }

  Future<void> _assignTask() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      if (assignToAll) {
        final membersSnapshot = await _firestore
            .collection('users')
            .where('userType', isEqualTo: 'member')
            .get();

        final membersDocs = membersSnapshot.docs;
        if (membersDocs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No members found to assign.")));
          return;
        }

        final assignedIds = membersDocs.map((d) => d.id).toList();
        final assignedNames = membersDocs
            .map((d) => (d.data() as Map<String, dynamic>?)?['name'] ?? 'Unnamed')
            .toList();
        final assignedEmails = membersDocs
            .map((d) => (d.data() as Map<String, dynamic>?)?['email'] ?? '')
            .toList();

        final taskRef = await _firestore.collection('tasks').add({
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'assignedTo': assignedIds,
          'assignedNames': assignedNames,
          'assignedEmails': assignedEmails,
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        for (var doc in membersDocs) {
          final mData = doc.data() as Map<String, dynamic>? ?? {};
          await _firestore.collection('notifications').add({
            'title': 'New Task Assigned',
            'message':
            'A new task "${titleController.text.trim()}" has been assigned to you.',
            'userId': doc.id,
            'userEmail': mData['email'] ?? '',
            'taskId': taskRef.id,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Task assigned to all members")),
        );
      } else if (selectedMember != null) {
        final docSnap =
        await _firestore.collection('users').doc(selectedMember).get();
        final memberData = docSnap.data() as Map<String, dynamic>? ?? {};
        final memberId = docSnap.id;
        final memberName = memberData['name'] ?? 'Unnamed';
        final memberEmail = memberData['email'] ?? '';

        final taskRef = await _firestore.collection('tasks').add({
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'assignedTo': [memberId],
          'assignedNames': [memberName],
          'assignedEmails': [memberEmail],
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('notifications').add({
          'title': 'New Task Assigned',
          'message':
          'You have a new task: "${titleController.text.trim()}".',
          'userId': memberId,
          'userEmail': memberEmail,
          'taskId': taskRef.id,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Task assigned to $memberName")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please select a member or choose 'Select All'")),
        );
      }

      titleController.clear();
      descriptionController.clear();
      setState(() {
        assignToAll = false;
        selectedMember = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to assign task: $e")),
      );
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _logout() async {
    await widget.authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
          (route) => false,
    );
  }

  /// 📊 DASHBOARD PAGE (with AI Assistant banner)
  Widget _buildDashboardPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, taskSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .where('userType', isEqualTo: 'member')
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!taskSnapshot.hasData || !userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = taskSnapshot.data!.docs;
            final membersDocs = userSnapshot.data!.docs;

            final Map<String, String> memberIdToName = {
              for (var d in membersDocs)
                d.id: ((d.data() as Map<String, dynamic>?)?['name'] ?? 'Unnamed')
            };

            int pending = tasks
                .where((task) =>
            ((task.data() as Map<String, dynamic>)['status'] ?? '') ==
                'Pending')
                .length;
            int completed = tasks
                .where((task) =>
            ((task.data() as Map<String, dynamic>)['status'] ?? '') ==
                'Completed')
                .length;

            final recentActivities = tasks.take(5).map((task) {
              final data = task.data() as Map<String, dynamic>? ?? {};
              final title = data['title'] ?? 'Untitled';
              final status = data['status'] ?? 'Pending';
              final assignedToRaw = data['assignedTo'];
              String assignedToStr = 'Unassigned';
              if (assignedToRaw is List) {
                final ids = List<String>.from(assignedToRaw);
                final names =
                ids.map((id) => memberIdToName[id] ?? id).toList();
                if (names.isEmpty) {
                  assignedToStr = 'Unassigned';
                } else if (names.length == 1) {
                  assignedToStr = names.first;
                } else {
                  assignedToStr =
                  '${names.take(2).join(", ")}${names.length > 2 ? " +${names.length - 2}" : ""}';
                }
              } else if (assignedToRaw is String) {
                assignedToStr = assignedToRaw;
              }
              return "📋 $title - $status (→ $assignedToStr)";
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🧠 AI Assistant banner
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AIAssistantPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.smart_toy_outlined,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              "AI Assistant 🤖\nAsk questions or generate ideas instantly.",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 18, color: Colors.deepPurple),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/banner.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome back, Admin 👋",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 10),
                  const Text("Here’s today’s workspace summary:",
                      style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard("Members", "${membersDocs.length}",
                          Icons.group, Colors.deepPurple),
                      _buildStatCard("Pending", "$pending",
                          Icons.pending_actions, Colors.orange),
                      _buildStatCard("Completed", "$completed",
                          Icons.check_circle, Colors.green),
                      _buildStatCard(
                          "Reports", "—", Icons.bar_chart, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("Recent Activities",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (recentActivities.isEmpty)
                    const Text("No recent activities found.")
                  else
                    for (var act in recentActivities)
                      _buildActivityItem(act),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAssignTaskPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('userType', isEqualTo: 'member')
          .snapshots(),
      builder: (context, snapshot) {
        final members = snapshot.data?.docs ?? [];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text("📝 Assign Task",
                  style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: "Title", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                    labelText: "Description", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: assignToAll ? null : selectedMember,
                items: [
                  const DropdownMenuItem(
                      value: 'all', child: Text('Select All Members')),
                  ...members.map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final name = (data['name'] ?? 'Unnamed') as String;
                    return DropdownMenuItem(value: doc.id, child: Text(name));
                  }),
                ],
                onChanged: (value) {
                  if (value == 'all') {
                    setState(() {
                      assignToAll = true;
                      selectedMember = null;
                    });
                  } else {
                    setState(() {
                      assignToAll = false;
                      selectedMember = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                    labelText: "Assign To", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _assignTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Assign Task"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsPage() => const Center(
      child: Text("📊 Reports Coming Soon",
          style: TextStyle(fontSize: 18, color: Colors.black54)));

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.bolt, color: Colors.deepPurple),
        title: Text(text),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.task_alt, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text("Admin Panel",
                style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ],
        ),
        actions: [
          // 🔔 NOTIFICATION ICON WITH GREEN DOT
          StreamBuilder<int>(
            stream: _unreadSubmissionsCount(),
            builder: (context, snapshot) {
              final hasUnread = (snapshot.data ?? 0) > 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.deepPurple),
                    onPressed: _showSubmissionsDialog,
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 18,
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : const AssetImage('assets/images/profile.png')
              as ImageProvider,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (choice) async {
              if (choice == 'Logout') {
                _logout();
              } else if (choice == 'Settings') {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfilePage()));
                _loadAdminProfile();
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(
                  value: 'Settings',
                  child: Row(children: [
                    Icon(Icons.settings_outlined,
                        color: Colors.deepPurple),
                    SizedBox(width: 10),
                    Text("Edit Profile")
                  ])),
              PopupMenuDivider(),
              PopupMenuItem(
                  value: 'Logout',
                  child: Row(children: [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text("Logout")
                  ])),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined), label: 'Members'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Assign'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined), label: 'Manage'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
        ],
      ),
    );
  }
}
