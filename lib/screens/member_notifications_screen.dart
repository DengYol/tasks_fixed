import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MemberNotificationsScreen extends StatelessWidget {
  const MemberNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 👇 Real-time updates from Firestore
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userType', isEqualTo: 'member')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data =
              notifications[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'No Title';
              final message = data['message'] ?? 'No Message';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active,
                      color: Colors.blueAccent),
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "$message\n${timestamp != null ? DateFormat('EEE, MMM d • h:mm a').format(timestamp) : ''}",
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
