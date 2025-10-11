import 'user_model.dart';

class TaskModel {
  final String id;
  final String description;
  final DateTime deadline; // Includes date & time
  final List<UserModel> assignedMembers;
  final UserModel assignedBy;
  final List<UserModel> completedMembers;
  final Map<String, String> approvalStatus; // memberId -> 'Pending' | 'Approved' | 'Denied'

  TaskModel({
    required this.id,
    required this.description,
    required this.deadline,
    required this.assignedMembers,
    required this.assignedBy,
    List<UserModel>? completedMembers,
  })  : completedMembers = completedMembers ?? [],
        approvalStatus = {
          for (var m in assignedMembers) m.uid: 'Pending',
        };

  /// Mark a member as completed
  void markCompleted(UserModel member) {
    if (!completedMembers.any((m) => m.uid == member.uid)) {
      completedMembers.add(member);
      approvalStatus[member.uid] = 'Pending'; // Reset approval on new submission
    }
  }

  /// Admin approves a member's task
  void approveMemberTask(String memberId) {
    if (approvalStatus.containsKey(memberId)) {
      approvalStatus[memberId] = 'Approved';
    }
  }

  /// Admin denies a member's task
  void denyMemberTask(String memberId) {
    if (approvalStatus.containsKey(memberId)) {
      approvalStatus[memberId] = 'Denied';
    }
  }

  /// Check if all assigned members have completed the task
  bool get isCompleted => completedMembers.length == assignedMembers.length;

  /// Get time left until deadline
  String get timeLeft {
    final now = DateTime.now();
    if (deadline.isBefore(now)) return 'Deadline passed';
    final difference = deadline.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    return '${days}d ${hours}h left';
  }

  /// Get member status map with approval
  Map<String, String> memberStatus() {
    Map<String, String> status = {};
    for (var member in assignedMembers) {
      final completion = completedMembers.any((m) => m.uid == member.uid)
          ? 'Submitted'
          : 'Pending';
      final approval = approvalStatus[member.uid] ?? 'Pending';
      status[member.name] = '$completion | $approval';
    }
    return status;
  }
}
