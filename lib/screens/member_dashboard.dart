import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

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
      _TasksPage(userId: user?.uid ?? ''),
      const _NotificationsPage(),
      const _SettingsPage(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 6,
        title: const Row(
          children: [
            Icon(Icons.task_alt, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "TASKS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile tapped!")),
                );
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.deepPurple),
              ),
            ),
          )
        ],
      ),

      // Main Content
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

//
// ✅ TASKS PAGE (with response and file upload)
//
class _TasksPage extends StatefulWidget {
  final String userId;
  const _TasksPage({required this.userId});

  @override
  State<_TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<_TasksPage> {
  final _responseControllers = <String, TextEditingController>{};
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No tasks assigned yet 📭",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        final tasks = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final data = task.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Untitled Task';
            final description = data['description'] ?? '';
            final completed = data['completed'] ?? false;

            _responseControllers.putIfAbsent(
                task.id, () => TextEditingController());

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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

                    // 📝 Text response field
                    TextField(
                      controller: _responseControllers[task.id],
                      decoration: InputDecoration(
                        hintText: "Write your response here...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 10),

                    // 📎 Upload & Submit buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          onPressed: _uploading
                              ? null
                              : () => _uploadFile(context, task.id),
                          label: Text(_uploading ? "Uploading..." : "Upload File"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          onPressed: () => _submitResponse(task.id),
                          label: const Text("Submit"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
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
        const SnackBar(content: Text("✅ File uploaded successfully!")),
      );
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
        const SnackBar(content: Text("Please type your response before submitting.")),
      );
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Response submitted successfully!")),
    );

    _responseControllers[taskId]?.clear();
  }
}

//
// 🔔 Notifications Page
//
class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "No new notifications 📭",
        style: TextStyle(fontSize: 18, color: Colors.black54),
      ),
    );
  }
}

//
// ⚙️ Settings Page
//
class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Settings ⚙️",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        _settingsTile(Icons.person_outline, "Edit Profile"),
        _settingsTile(Icons.lock_outline, "Change Password"),
        _settingsTile(Icons.logout, "Logout"),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
