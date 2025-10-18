import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'edit_profile_page.dart';
import 'ai_assistant_page.dart'; // 👈 AI Assistant screen

class MemberDashboard extends StatefulWidget {
  final AuthService authService;

  const MemberDashboard({super.key, required this.authService});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const _HomePage(),
      _TasksPage(userId: user?.uid ?? ''),
      const _NotificationsPage(),
      _SettingsPage(authService: widget.authService),
    ]);
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _openProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        title: const Row(
          children: [
            Icon(Icons.task_alt, color: Colors.black87),
            SizedBox(width: 8),
            Text(
              "TasksApp",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openProfilePage,
            icon: const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user?.uid)
            .where('isRead', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.teal,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 8,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined), label: 'Home'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.task_outlined), label: 'Tasks'),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_none),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          height: 10,
                          width: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Notifications',
              ),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined), label: 'Settings'),
            ],
          );
        },
      ),
    );
  }
}

//
// 🏠 Home Page — AI button above the banner
//
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? 'Member';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👇 AI Assistant button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIAssistantPage()),
                );
              },
              icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
              label: const Text(
                "AI Task Assistant",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // 🖼️ Banner
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Image.asset(
              'assets/images/banner.jpg',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Welcome back, $username 👋",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Here’s what’s new for you today:",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

//
// ✅ Tasks Page — now closes form and notifies admin
//
class _TasksPage extends StatefulWidget {
  final String userId;
  const _TasksPage({required this.userId});

  @override
  State<_TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<_TasksPage> {
  final _responseControllers = <String, TextEditingController>{};
  final _submittedTasks = <String>{};
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', arrayContains: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No tasks assigned yet 📭",
                style: TextStyle(fontSize: 18, color: Colors.black54)),
          );
        }

        final tasks = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final data = task.data() as Map<String, dynamic>;
            final taskId = task.id;
            final title = data['title'] ?? 'Untitled Task';
            final description = data['description'] ?? '';

            _responseControllers.putIfAbsent(
                taskId, () => TextEditingController());

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(taskId)
                  .collection('submissions')
                  .doc(widget.userId)
                  .snapshots(),
              builder: (context, submissionSnapshot) {
                bool isSubmitted = submissionSnapshot.hasData &&
                    submissionSnapshot.data?.exists == true;

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(description,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black54)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              isSubmitted
                                  ? Icons.check_circle
                                  : Icons.hourglass_empty,
                              color: isSubmitted
                                  ? Colors.green
                                  : Colors.orangeAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSubmitted ? "Submitted" : "Not Submitted",
                              style: TextStyle(
                                  color: isSubmitted
                                      ? Colors.green
                                      : Colors.orangeAccent,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!isSubmitted)
                          Column(
                            children: [
                              TextField(
                                controller: _responseControllers[taskId],
                                decoration: InputDecoration(
                                  hintText: "Write your response...",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.upload_file),
                                    label: Text(_uploading
                                        ? "Uploading..."
                                        : "Upload File"),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal),
                                    onPressed: _uploading
                                        ? null
                                        : () => _uploadFile(context, taskId),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.send),
                                    label: const Text("Submit"),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green),
                                    onPressed: () => _submitResponse(taskId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _uploadFile(BuildContext context, String taskId) async {
    try {
      setState(() => _uploading = true);
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;
      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      final ref = FirebaseStorage.instance
          .ref()
          .child('submissions/${widget.userId}/$taskId/$fileName');
      await ref.putFile(File(filePath));
      final fileUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .collection('submissions')
          .doc(widget.userId)
          .set({
        'fileUrl': fileUrl,
        'submittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ File uploaded successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Upload failed: $e")));
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _submitResponse(String taskId) async {
    final response = _responseControllers[taskId]?.text.trim();
    if (response == null || response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Type your response first.")));
      return;
    }

    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .collection('submissions')
        .doc(widget.userId)
        .set({
      'response': response,
      'submittedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ Create notifications for admin & member
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': 'admin', // Target admin
      'title': 'New Task Submission',
      'message': 'A member has submitted "$taskId".',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': widget.userId,
      'title': 'Task Submitted',
      'message': 'Your task "$taskId" was successfully submitted.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    setState(() {
      _responseControllers[taskId]?.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Response submitted successfully!")));
  }
}

//
// 🔔 Notifications Page — shows list from Firestore
//
class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No new notifications 📭",
                style: TextStyle(fontSize: 18, color: Colors.black54)),
          );
        }

        final notifications = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final data = notifications[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Notification';
            final message = data['message'] ?? '';
            final isRead = data['isRead'] ?? false;

            return Card(
              color: isRead ? Colors.white : Colors.teal.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(message),
                trailing: IconButton(
                  icon: const Icon(Icons.done, color: Colors.teal),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(notifications[index].id)
                        .update({'isRead': true});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

//
// ⚙️ Settings Page
//
class _SettingsPage extends StatelessWidget {
  final AuthService authService;
  const _SettingsPage({required this.authService});

  Future<void> _logout(BuildContext context) async {
    await authService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(authService: authService)),
          (route) => false,
    );
  }

  void _goToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Settings ⚙️",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _settingsTile(Icons.person_outline, "Edit Profile",
            onTap: () => _goToEditProfile(context)),
        _settingsTile(Icons.logout, "Logout", onTap: () => _logout(context)),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
