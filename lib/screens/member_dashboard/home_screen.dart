import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Color _getTaskPriorityColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    if (difference < 0) return Colors.red.shade300; // Overdue
    if (difference == 0) return Colors.orange.shade300; // Due today
    if (difference <= 7) return Colors.yellow.shade200; // This week
    return Colors.green.shade200; // Later
  }

  double _calculateTaskProgress(Map<String, dynamic> task) {
    if (task.containsKey('completed') && task['completed'] is bool) {
      return task['completed'] ? 1.0 : (task['progress'] ?? 0) / 100;
    }
    return 0.0;
  }

  Color _getProjectColor(String status, DateTime dueDate) {
    final now = DateTime.now();
    if (status == 'Completed') return Colors.green.shade200;
    if (status == 'In Progress') return Colors.orange.shade200;
    if (dueDate.isBefore(now)) return Colors.red.shade200; // Overdue
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final tasksRef = FirebaseFirestore.instance.collection('tasks');
    final projectsRef = FirebaseFirestore.instance.collection('projects');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Activity Overview",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 🔹 Tasks Section
            StreamBuilder<QuerySnapshot>(
              stream: tasksRef.orderBy('dueDate').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!.docs;
                if (tasks.isEmpty) {
                  return const Text("No tasks assigned yet.");
                }

                final now = DateTime.now();
                final dueToday = <QueryDocumentSnapshot>[];
                final dueThisWeek = <QueryDocumentSnapshot>[];
                final later = <QueryDocumentSnapshot>[];

                for (var task in tasks) {
                  final data = task.data() as Map<String, dynamic>;
                  final dueDate = (data['dueDate'] as Timestamp).toDate();
                  final difference = dueDate.difference(now).inDays;

                  if (difference == 0) {
                    dueToday.add(task);
                  } else if (difference > 0 && difference <= 7) {
                    dueThisWeek.add(task);
                  } else {
                    later.add(task);
                  }
                }

                Widget buildTaskCard(QueryDocumentSnapshot task) {
                  final data = task.data() as Map<String, dynamic>;
                  final dueDate = (data['dueDate'] as Timestamp).toDate();
                  final progress = _calculateTaskProgress(data);
                  final color = _getTaskPriorityColor(dueDate);

                  return Card(
                    color: color.withOpacity(0.4),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        data['title'] ?? 'Untitled Task',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Due: ${DateFormat.yMMMd().format(dueDate)}"),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            color: Colors.purple,
                            backgroundColor: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 4),
                          Text("${(progress * 100).toStringAsFixed(0)}% done"),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dueToday.isNotEmpty) ...[
                      const Text("🔥 Tasks Due Today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...dueToday.map(buildTaskCard),
                      const SizedBox(height: 12),
                    ],
                    if (dueThisWeek.isNotEmpty) ...[
                      const Text("⏳ Tasks Due This Week", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...dueThisWeek.map(buildTaskCard),
                      const SizedBox(height: 12),
                    ],
                    if (later.isNotEmpty) ...[
                      const Text("📅 Later Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...later.map(buildTaskCard),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // 🔹 Projects Section
            const Text(
              "Projects",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: projectsRef.orderBy('dueDate').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final projects = snapshot.data!.docs;
                if (projects.isEmpty) {
                  return const Text("No projects yet.");
                }

                return Column(
                  children: projects.map((project) {
                    final data = project.data() as Map<String, dynamic>;
                    final dueDate = (data['dueDate'] as Timestamp).toDate();
                    final status = data['status'] ?? "Pending";
                    final color = _getProjectColor(status, dueDate);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProjectDetailsScreen(project: project),
                          ),
                        );
                      },
                      child: Card(
                        color: color.withOpacity(0.4),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            data['title'] ?? "Untitled Project",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Due: ${DateFormat.yMMMd().format(dueDate)}\nStatus: $status"),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Project Details Screen
class ProjectDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final data = project.data() as Map<String, dynamic>;
    final dueDate = (data['dueDate'] as Timestamp).toDate();
    final status = data['status'] ?? "Pending";

    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] ?? "Project Details"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📅 Due Date: ${DateFormat.yMMMd().format(dueDate)}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("🟢 Status: $status", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("📝 Description:", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(data['description'] ?? "No description available."),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                await project.reference.delete();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.delete),
              label: const Text("Delete Project"),
            ),
          ],
        ),
      ),
    );
  }
}
