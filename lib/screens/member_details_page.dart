import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemberDetailsPage extends StatelessWidget {
  final String memberId;
  final String memberName;
  final String userType;
  final String createdAt;

  const MemberDetailsPage({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.userType,
    required this.createdAt,
  });

  Future<void> _removeMember(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Member"),
        content:
        Text("Are you sure you want to remove $memberName from members?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ $memberName removed successfully")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to remove member: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(memberName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.person, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 10),
            Text(
              memberName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "User Type: $userType",
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              "Joined: $createdAt",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _removeMember(context),
              icon: const Icon(Icons.delete),
              label: const Text("Remove Member"),
            ),
          ],
        ),
      ),
    );
  }
}
