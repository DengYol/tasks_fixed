import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import 'project_details_page.dart'; // 👈 new import for details screen

class ProjectPage extends StatefulWidget {
  const ProjectPage({Key? key}) : super(key: key);

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Project>> getProjects() {
    return _firestore.collection('projects').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Project.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> _addProjectDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDate;
    List<String> selectedMembers = [];

    final membersSnapshot = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'member')
        .get();
    final members = membersSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['fullName'] ?? 'Unnamed',
        'email': data['email'] ?? 'No email',
      };
    }).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Add Project"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Project Name"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration:
                    const InputDecoration(labelText: "Project Description"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? "No deadline selected"
                              : "Deadline: ${selectedDate!.toLocal().toString().split(' ')[0]}",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today,
                            color: Colors.purple),
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Assign to Members",
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final isSelected =
                        selectedMembers.contains(member['id']);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(member['name']),
                          subtitle: Text(member['email']),
                          activeColor: Colors.purple,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedMembers.add(member['id']);
                              } else {
                                selectedMembers.remove(member['id']);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Save"),
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    await _firestore.collection('projects').add({
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'deadline': selectedDate != null
                          ? Timestamp.fromDate(selectedDate!)
                          : null,
                      'status': 'Ongoing',
                      'assignedMembers': selectedMembers,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

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

  bool _shouldDisplay(Project project) {
    if (project.status.toLowerCase() == 'completed') return false;
    if (project.deadline != null &&
        project.deadline!.isBefore(DateTime.now())) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Projects"),
        backgroundColor: Colors.purple.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProjectDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<Project>>(
        stream: getProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No projects found"));
          }

          final projects =
          snapshot.data!.where(_shouldDisplay).toList(growable: false);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              itemCount: projects.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  color: Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailsPage(project: project),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            project.deadline != null
                                ? "Due: ${project.deadline!.toLocal().toString().split(' ')[0]}"
                                : "No deadline",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(project.status)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              project.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(project.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
