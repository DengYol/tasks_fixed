import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final DateTime? deadline;
  final String status;
  final List<String> assignedMembers; // ✅ NEW FIELD

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.deadline,
    required this.status,
    required this.assignedMembers, // ✅ NEW PARAMETER
  });

  // ✅ Convert Firestore document to Project object
  factory Project.fromMap(Map<String, dynamic> data, String documentId) {
    return Project(
      id: documentId,
      name: data['name'] ?? 'Untitled Project',
      description: data['description'] ?? 'No description provided',
      deadline: data['deadline'] != null
          ? (data['deadline'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'Ongoing',
      assignedMembers: data['assignedMembers'] != null
          ? List<String>.from(data['assignedMembers'])
          : [], // ✅ Safely convert list
    );
  }

  // ✅ Convert Project object to Firestore format
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'deadline': deadline,
      'status': status,
      'assignedMembers': assignedMembers, // ✅ Include this field
    };
  }
}
