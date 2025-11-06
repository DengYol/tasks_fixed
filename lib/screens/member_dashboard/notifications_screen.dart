import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in.")),
      );
    }

    final notificationsQuery = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.docs ?? [];

          if (data.isEmpty) {
            return const Center(child: Text("No new notifications."));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final notification = data[index];
              final notifData = notification.data() as Map<String, dynamic>;
              final isRead = notifData['read'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isRead ? Colors.white : Colors.deepPurple.shade50,
                child: ListTile(
                  title: Text(notifData['title'] ?? "No Title"),
                  subtitle: Text(notifData['message'] ?? "No Message"),
                  trailing: isRead
                      ? null
                      : const Icon(Icons.circle, color: Colors.deepPurple, size: 12),
                  onTap: () async {
                    // Mark as read when tapped
                    await notification.reference.update({'read': true});
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
