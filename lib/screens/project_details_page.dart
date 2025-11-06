import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ProjectDetailsPage extends StatelessWidget {
  final Project project;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProjectDetailsPage({super.key, required this.project});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.redAccent;
      default:
        return Colors.purple;
    }
  }

  Future<void> _deleteProject(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Project"),
        content: Text("Are you sure you want to delete '${project.name}' project?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('projects').doc(project.id).delete();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        backgroundColor: Colors.purple.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _deleteProject(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              project.name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              project.description.isNotEmpty
                  ? project.description
                  : "No description provided.",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.purple),
                const SizedBox(width: 10),
                Text(
                  project.deadline != null
                      ? "Deadline: ${project.deadline!.toLocal().toString().split(' ')[0]}"
                      : "No deadline set",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(project.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                project.status,
                style: TextStyle(
                  color: _getStatusColor(project.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Divider(),
            const Text(
              "Assigned Members:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // ✅ Fix for Firestore empty query issue
            if (project.assignedMembers == null ||
                project.assignedMembers!.isEmpty)
              const Text("No members assigned yet."),
            if (project.assignedMembers != null &&
                project.assignedMembers!.isNotEmpty)
              FutureBuilder<QuerySnapshot>(
                future: _firestore
                    .collection('users')
                    .where(FieldPath.documentId,
                    whereIn: project.assignedMembers!)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text("Error loading members.");
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No members found.");
                  }

                  final members = snapshot.data!.docs;
                  return Column(
                    children: members.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        title: Text(data['fullName'] ?? 'Unnamed'),
                        subtitle: Text(data['email'] ?? ''),
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
