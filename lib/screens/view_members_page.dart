import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ViewMembersPage extends StatefulWidget {
  final AuthService authService;

  const ViewMembersPage({super.key, required this.authService});

  @override
  State<ViewMembersPage> createState() => _ViewMembersPageState();
}

class _ViewMembersPageState extends State<ViewMembersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'member')
          .get();

      final memberList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['fullName'] ?? 'No Name',
          'email': data['email'] ?? 'No Email',
          'createdAt': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0]
              : '—',
        };
      }).toList();

      setState(() {
        members = memberList;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading members: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
          ? const Center(child: Text("No members found"))
          : RefreshIndicator(
        onRefresh: _loadMembers,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(member['name']),
                subtitle: Text(member['email']),
                trailing: Text(
                  member['createdAt'],
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
