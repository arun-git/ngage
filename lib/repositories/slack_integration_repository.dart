import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Repository for Slack integration data access
/// 
/// Provides a data access layer for Slack integrations,
/// abstracting Firebase Firestore operations.
class SlackIntegrationRepository {
  final FirebaseFirestore _firestore;
  
  SlackIntegrationRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _integrationsCollection => _firestore.collection('slack_integrations');

  /// Create a new Slack integration
  Future<void> createIntegration(SlackIntegration integration) async {
    try {
      await _integrationsCollection.doc(integration.id).set(integration.toJson());
    } catch (e) {
      throw Exception('Failed to create Slack integration in database: $e');
    }
  }

  /// Get a Slack integration by ID
  Future<SlackIntegration?> getIntegrationById(String integrationId) async {
    try {
      final doc = await _integrationsCollection.doc(integrationId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return SlackIntegration.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get Slack integration from database: $e');
    }
  }

  /// Get Slack integration by group ID
  Future<SlackIntegration?> getIntegrationByGroupId(String groupId) async {
    try {
      final query = await _integrationsCollection
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final data = query.docs.first.data() as Map<String, dynamic>;
      return SlackIntegration.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get Slack integration by group ID from database: $e');
    }
  }

  /// Update a Slack integration
  Future<void> updateIntegration(SlackIntegration integration) async {
    try {
      await _integrationsCollection.doc(integration.id).update(integration.toJson());
    } catch (e) {
      throw Exception('Failed to update Slack integration in database: $e');
    }
  }

  /// Delete a Slack integration
  Future<void> deleteIntegration(String integrationId) async {
    try {
      await _integrationsCollection.doc(integrationId).delete();
    } catch (e) {
      throw Exception('Failed to delete Slack integration from database: $e');
    }
  }

  /// Get all active Slack integrations
  Future<List<SlackIntegration>> getActiveIntegrations() async {
    try {
      final query = await _integrationsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => SlackIntegration.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active Slack integrations from database: $e');
    }
  }

  /// Get Slack integrations by workspace ID
  Future<List<SlackIntegration>> getIntegrationsByWorkspaceId(String workspaceId) async {
    try {
      final query = await _integrationsCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => SlackIntegration.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get Slack integrations by workspace ID from database: $e');
    }
  }

  /// Update channel mappings for an integration
  Future<void> updateChannelMappings(String integrationId, Map<String, String> channelMappings) async {
    try {
      await _integrationsCollection.doc(integrationId).update({
        'channelMappings': channelMappings,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update channel mappings in database: $e');
    }
  }

  /// Activate or deactivate an integration
  Future<void> setIntegrationActive(String integrationId, bool isActive) async {
    try {
      await _integrationsCollection.doc(integrationId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update integration status in database: $e');
    }
  }

  /// Update bot token for an integration
  Future<void> updateBotToken(String integrationId, String botToken) async {
    try {
      await _integrationsCollection.doc(integrationId).update({
        'botToken': botToken,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update bot token in database: $e');
    }
  }

  /// Update user token for an integration
  Future<void> updateUserToken(String integrationId, String? userToken) async {
    try {
      await _integrationsCollection.doc(integrationId).update({
        'userToken': userToken,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update user token in database: $e');
    }
  }

  /// Get integrations that need to send notifications for a specific type
  Future<List<SlackIntegration>> getIntegrationsForNotificationType(String notificationType) async {
    try {
      final query = await _integrationsCollection
          .where('isActive', isEqualTo: true)
          .get();

      final integrations = query.docs
          .map((doc) => SlackIntegration.fromJson(doc.data() as Map<String, dynamic>))
          .where((integration) => integration.channelMappings.containsKey(notificationType))
          .toList();

      return integrations;
    } catch (e) {
      throw Exception('Failed to get integrations for notification type from database: $e');
    }
  }

  /// Stream Slack integration for real-time updates
  Stream<SlackIntegration?> streamIntegrationByGroupId(String groupId) {
    try {
      return _integrationsCollection
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return null;
            }
            final data = snapshot.docs.first.data() as Map<String, dynamic>;
            return SlackIntegration.fromJson(data);
          });
    } catch (e) {
      throw Exception('Failed to stream Slack integration from database: $e');
    }
  }

  /// Stream all active integrations for real-time updates
  Stream<List<SlackIntegration>> streamActiveIntegrations() {
    try {
      return _integrationsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SlackIntegration.fromJson(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream active Slack integrations from database: $e');
    }
  }

  /// Check if a group has an active Slack integration
  Future<bool> hasActiveIntegration(String groupId) async {
    try {
      final query = await _integrationsCollection
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check for active integration in database: $e');
    }
  }

  /// Batch update multiple integrations
  Future<void> batchUpdateIntegrations(List<SlackIntegration> integrations) async {
    try {
      final batch = _firestore.batch();
      
      for (final integration in integrations) {
        final docRef = _integrationsCollection.doc(integration.id);
        batch.update(docRef, integration.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update Slack integrations in database: $e');
    }
  }
}