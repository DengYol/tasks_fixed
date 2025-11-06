import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Firestore query: only tasks assigned to this user
    final tasksQuery = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: currentUser?.uid)
        .orderBy('dueDate');

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tasks"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tasksQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.docs ?? [];

          if (data.isEmpty) {
            return const Center(child: Text("No tasks assigned to you."));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final task = data[index];
              final completed = task['completed'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(task['title']),
                  subtitle: Text("Due: ${task['dueDate']}"),
                  trailing: Icon(
                    completed ? Icons.check_circle : Icons.hourglass_bottom,
                    color: completed ? Colors.green : Colors.orange,
                  ),
                  onTap: () async {
                    // Optionally allow member to mark task as completed
                    if (!completed) {
                      await FirebaseFirestore.instance
                          .collection('tasks')
                          .doc(task.id)
                          .update({'completed': true});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
