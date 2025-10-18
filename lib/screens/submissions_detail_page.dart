import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionsDetailPage extends StatelessWidget {
  final String taskId;
  final String title;

  const SubmissionsDetailPage({
    super.key,
    required this.taskId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: Text("Submissions for $title")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('submissions')
            .where('taskId', isEqualTo: taskId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No submissions yet"));
          }

          final submissions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final data = submissions[index].data() as Map<String, dynamic>;
              final studentName = data['studentName'] ?? 'Unknown';
              final submissionText = data['content'] ?? 'No content';
              final submittedAt = (data['submittedAt'] as Timestamp).toDate();

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "$submissionText\n\nSubmitted: ${submittedAt.toLocal()}",
                    style: const TextStyle(fontSize: 13),
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
