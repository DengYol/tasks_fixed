import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a notification to Firestore.
  /// It will automatically create the collection if it doesn't exist.
  Future<void> sendNotification({
    required String title,
    required String message,
    required String userId,
    bool isRead = false,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'userId': userId,
        'isRead': isRead,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Notification added for $userId');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  /// Fetches all notifications for a specific user, sorted by latest first.
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Deletes a specific notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }
}
