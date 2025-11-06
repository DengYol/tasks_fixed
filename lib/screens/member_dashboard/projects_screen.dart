import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  DateTime _parseDueDate(dynamic dueDate) {
    // Handles both Timestamp and String
    if (dueDate is Timestamp) return dueDate.toDate();
    if (dueDate is String) return DateTime.tryParse(dueDate) ?? DateTime.now();
    return DateTime.now();
  }

  Color _getProjectColor(String status, DateTime dueDate) {
    final now = DateTime.now();
    if (status == 'Completed') return Colors.green.shade200;
    if (status == 'In Progress') return Colors.orange.shade200;
    if (dueDate.isBefore(now)) return Colors.red.shade200; // overdue
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Query projects created by the current member
    final projectsQuery = FirebaseFirestore.instance
        .collection('projects')
        .where('createdBy', isEqualTo: currentUser?.uid)
        .orderBy('dueDate');

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Projects"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: projectsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.docs ?? [];

          if (data.isEmpty) {
            return const Center(child: Text("No projects yet."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final project = data[index];
              final projectData = project.data() as Map<String, dynamic>;
              final dueDate = _parseDueDate(projectData['dueDate']);
              final status = projectData['status'] ?? 'Not Started';
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
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          projectData['title'] ?? 'Untitled Project',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                            "Due: ${dueDate.toLocal().toString().split(' ')[0]}"),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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

// Project Details
class ProjectDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot project;

  const ProjectDetailsScreen({super.key, required this.project});

  DateTime _parseDueDate(dynamic dueDate) {
    if (dueDate is Timestamp) return dueDate.toDate();
    if (dueDate is String) return DateTime.tryParse(dueDate) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final data = project.data() as Map<String, dynamic>;
    final dueDate = _parseDueDate(data['dueDate']);
    final status = data['status'] ?? "Not Started";

    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] ?? "Project Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📅 Due Date: ${dueDate.toLocal().toString().split(' ')[0]}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("🟢 Status: $status", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("📝 Description:",
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

// Create Project
class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  String _status = 'Not Started';

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _createProject() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (_titleController.text.isEmpty || _dueDate == null) return;

    await FirebaseFirestore.instance.collection('projects').add({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'status': _status,
      'dueDate': Timestamp.fromDate(_dueDate!),
      'createdBy': currentUser.uid,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Project"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Project Title"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(_dueDate == null
                    ? "Select Due Date"
                    : "Due: ${_dueDate!.toLocal().toString().split(' ')[0]}"),
                const Spacer(),
                ElevatedButton(
                  onPressed: _pickDueDate,
                  child: const Text("Pick Date"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              items: ['Not Started', 'In Progress', 'Completed']
                  .map((status) =>
                  DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) => setState(() => _status = value!),
              decoration: const InputDecoration(labelText: "Status"),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createProject,
                child: const Text("Create Project"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
