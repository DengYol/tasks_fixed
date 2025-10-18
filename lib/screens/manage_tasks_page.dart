import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'submissions_detail_page.dart';

class ManageTasksPage extends StatefulWidget {
  const ManageTasksPage({super.key});

  @override
  State<ManageTasksPage> createState() => _ManageTasksPageState();
}

class _ManageTasksPageState extends State<ManageTasksPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _hasUnreadNotifications = snapshot.docs.isNotEmpty;
      });
    });
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus, String taskTitle) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus,
      });

      await _firestore.collection('notifications').add({
        'title': 'Task $newStatus',
        'message': 'The task "$taskTitle" was marked as $newStatus.',
        'timestamp': DateTime.now(),
        'userType': 'member',
        'isRead': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Task marked as $newStatus")),
      );
    } catch (e) {
      debugPrint("Error updating task: $e");
    }
  }

  Future<void> _deleteTask(String taskId, String taskTitle) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();

      await _firestore.collection('notifications').add({
        'title': 'Task Deleted',
        'message': 'The task "$taskTitle" has been deleted by admin.',
        'timestamp': DateTime.now(),
        'userType': 'member',
        'isRead': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task deleted")),
      );
    } catch (e) {
      debugPrint("Error deleting task: $e");
    }
  }

  void _openSubmissionsPage(String taskId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmissionsDetailPage(taskId: taskId, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Tasks"),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // Mark notifications as read
                  _firestore
                      .collection('notifications')
                      .where('isRead', isEqualTo: false)
                      .get()
                      .then((snapshot) {
                    for (var doc in snapshot.docs) {
                      doc.reference.update({'isRead': true});
                    }
                  });
                  setState(() {
                    _hasUnreadNotifications = false;
                  });
                },
              ),
              if (_hasUnreadNotifications)
                const Positioned(
                  right: 12,
                  top: 12,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: Colors.green,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('tasks').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tasks found"));
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final data = tasks[index].data() as Map<String, dynamic>;
              final taskId = tasks[index].id;
              final title = data['title'] ?? 'Untitled';
              final desc = data['description'] ?? '';
              final assignedTo = data['assignedTo'] ?? 'N/A';
              final status = data['status'] ?? 'Pending';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    status == 'Completed' ? Icons.check_circle : Icons.pending_actions,
                    color: status == 'Completed' ? Colors.green : Colors.orange,
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$desc\nAssigned to: $assignedTo"),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (choice) {
                      if (choice == 'Mark Completed') {
                        _updateTaskStatus(taskId, 'Completed', title);
                      } else if (choice == 'Mark Pending') {
                        _updateTaskStatus(taskId, 'Pending', title);
                      } else if (choice == 'Delete') {
                        _deleteTask(taskId, title);
                      } else if (choice == 'View Submissions') {
                        _openSubmissionsPage(taskId, title);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(value: 'View Submissions', child: Text('View Submissions')),
                      const PopupMenuItem(value: 'Mark Completed', child: Text('Mark Completed')),
                      const PopupMenuItem(value: 'Mark Pending', child: Text('Mark Pending')),
                      const PopupMenuItem(
                        value: 'Delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
