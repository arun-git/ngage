import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Repository for managing notification data in Firestore
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for notifications
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Collection reference for notification preferences
  CollectionReference get _preferencesCollection =>
      _firestore.collection('notification_preferences');

  /// Create a new notification
  Future<void> createNotification(Notification notification) async {
    await _notificationsCollection.doc(notification.id).set(notification.toJson());
  }

  /// Get notifications for a specific member
  Future<List<Notification>> getMemberNotifications(
    String memberId, {
    int limit = 50,
    DateTime? lastCreatedAt,
  }) async {
    Query query = _notificationsCollection
        .where('recipientId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true);

    if (lastCreatedAt != null) {
      query = query.startAfter([lastCreatedAt.toIso8601String()]);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Notification.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get unread notifications count for a member
  Future<int> getUnreadNotificationsCount(String memberId) async {
    final snapshot = await _notificationsCollection
        .where('recipientId', isEqualTo: memberId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    
    return snapshot.count ?? 0;
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({
      'isRead': true,
      'readAt': DateTime.now().toIso8601String(),
    });
  }

  /// Mark all notifications as read for a member
  Future<void> markAllNotificationsAsRead(String memberId) async {
    final batch = _firestore.batch();
    final snapshot = await _notificationsCollection
        .where('recipientId', isEqualTo: memberId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsCollection.doc(notificationId).delete();
  }

  /// Get scheduled notifications that are ready to be sent
  Future<List<Notification>> getScheduledNotifications() async {
    final now = DateTime.now();
    final snapshot = await _notificationsCollection
        .where('scheduledAt', isLessThanOrEqualTo: now.toIso8601String())
        .get();

    return snapshot.docs
        .map((doc) => Notification.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Stream of notifications for real-time updates
  Stream<List<Notification>> streamMemberNotifications(String memberId) {
    return _notificationsCollection
        .where('recipientId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Notification.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get notification preferences for a member
  Future<NotificationPreferences?> getNotificationPreferences(String memberId) async {
    final doc = await _preferencesCollection.doc(memberId).get();
    if (!doc.exists) return null;
    
    return NotificationPreferences.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Save notification preferences for a member
  Future<void> saveNotificationPreferences(NotificationPreferences preferences) async {
    await _preferencesCollection.doc(preferences.memberId).set(preferences.toJson());
  }

  /// Get default notification preferences for a member
  NotificationPreferences getDefaultPreferences(String memberId) {
    return NotificationPreferences(
      memberId: memberId,
      updatedAt: DateTime.now(),
    );
  }

  /// Batch create multiple notifications
  Future<void> createNotificationsBatch(List<Notification> notifications) async {
    final batch = _firestore.batch();
    
    for (final notification in notifications) {
      final docRef = _notificationsCollection.doc(notification.id);
      batch.set(docRef, notification.toJson());
    }
    
    await batch.commit();
  }

  /// Delete old notifications (cleanup)
  Future<void> deleteOldNotifications({Duration olderThan = const Duration(days: 30)}) async {
    final cutoffDate = DateTime.now().subtract(olderThan);
    final snapshot = await _notificationsCollection
        .where('createdAt', isLessThan: cutoffDate.toIso8601String())
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Get notifications by type for analytics
  Future<List<Notification>> getNotificationsByType(
    NotificationType type, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    Query query = _notificationsCollection.where('type', isEqualTo: type.value);

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String());
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Notification.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }
}