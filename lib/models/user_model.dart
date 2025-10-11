enum UserRole { admin, member }

class UserModel {
  final String uid;
  final String name;
  final String email;
  String password; // ✅ Mutable now, so it can be updated
  final UserRole role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}
