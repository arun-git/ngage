import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/integration.dart';
import '../models/enums.dart';

/// Repository for managing multi-platform integrations in Firestore
class IntegrationRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'integrations';

  IntegrationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates a new integration
  Future<void> createIntegration(Integration integration) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(integration.id)
          .set(integration.toJson());
    } catch (e) {
      throw Exception('Failed to create integration: $e');
    }
  }

  /// Gets integration by ID
  Future<Integration?> getIntegrationById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return Integration.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get integration: $e');
    }
  }

  /// Gets all integrations for a group
  Future<List<Integration>> getGroupIntegrations(String groupId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Integration.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get group integrations: $e');
    }
  }

  /// Gets active integrations for a group
  Future<List<Integration>> getActiveGroupIntegrations(String groupId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Integration.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active group integrations: $e');
    }
  }

  /// Gets integrations by type for a group
  Future<List<Integration>> getGroupIntegrationsByType(
    String groupId, 
    IntegrationType type
  ) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('groupId', isEqualTo: groupId)
          .where('type', isEqualTo: type.value)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Integration.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get group integrations by type: $e');
    }
  }

  /// Updates an integration
  Future<void> updateIntegration(Integration integration) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(integration.id)
          .update(integration.toJson());
    } catch (e) {
      throw Exception('Failed to update integration: $e');
    }
  }

  /// Sets integration active status
  Future<Integration> setIntegrationActive(String integrationId, bool isActive) async {
    try {
      final integration = await getIntegrationById(integrationId);
      if (integration == null) {
        throw Exception('Integration not found: $integrationId');
      }

      final updatedIntegration = integration.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      await updateIntegration(updatedIntegration);
      return updatedIntegration;
    } catch (e) {
      throw Exception('Failed to set integration active status: $e');
    }
  }

  /// Updates channel mappings for an integration
  Future<void> updateChannelMappings(
    String integrationId, 
    Map<String, String> channelMappings
  ) async {
    try {
      await _firestore.collection(_collection).doc(integrationId).update({
        'channelMappings': channelMappings,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update channel mappings: $e');
    }
  }

  /// Updates integration configuration
  Future<void> updateConfiguration(
    String integrationId, 
    Map<String, dynamic> configuration
  ) async {
    try {
      await _firestore.collection(_collection).doc(integrationId).update({
        'configuration': configuration,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update integration configuration: $e');
    }
  }

  /// Deletes an integration
  Future<void> deleteIntegration(String integrationId) async {
    try {
      await _firestore.collection(_collection).doc(integrationId).delete();
    } catch (e) {
      throw Exception('Failed to delete integration: $e');
    }
  }

  /// Gets integrations that need to send notifications for a specific type
  Future<List<Integration>> getIntegrationsForNotificationType(
    String notificationType
  ) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final integrations = query.docs
          .map((doc) => Integration.fromJson(doc.data()))
          .where((integration) => 
            integration.channelMappings.containsKey(notificationType))
          .toList();

      return integrations;
    } catch (e) {
      throw Exception('Failed to get integrations for notification type: $e');
    }
  }

  /// Streams integrations for real-time updates
  Stream<List<Integration>> streamGroupIntegrations(String groupId) {
    try {
      return _firestore
          .collection(_collection)
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Integration.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream group integrations: $e');
    }
  }

  /// Streams active integrations for real-time updates
  Stream<List<Integration>> streamActiveGroupIntegrations(String groupId) {
    try {
      return _firestore
          .collection(_collection)
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Integration.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream active group integrations: $e');
    }
  }

  /// Checks if a group has an active integration of a specific type
  Future<bool> hasActiveIntegration(String groupId, IntegrationType type) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('groupId', isEqualTo: groupId)
          .where('type', isEqualTo: type.value)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check for active integration: $e');
    }
  }

  /// Gets integration statistics for analytics
  Future<Map<String, dynamic>> getIntegrationStatistics() async {
    try {
      final allIntegrations = await _firestore.collection(_collection).get();
      
      final stats = <String, dynamic>{
        'total': allIntegrations.docs.length,
        'active': 0,
        'inactive': 0,
        'byType': <String, int>{},
        'byGroup': <String, int>{},
      };

      for (final doc in allIntegrations.docs) {
        final integration = Integration.fromJson(doc.data());
        
        if (integration.isActive) {
          stats['active']++;
        } else {
          stats['inactive']++;
        }

        // Count by type
        final typeKey = integration.type.value;
        stats['byType'][typeKey] = (stats['byType'][typeKey] ?? 0) + 1;

        // Count by group
        final groupKey = integration.groupId;
        stats['byGroup'][groupKey] = (stats['byGroup'][groupKey] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get integration statistics: $e');
    }
  }

  /// Batch updates multiple integrations
  Future<void> batchUpdateIntegrations(List<Integration> integrations) async {
    try {
      final batch = _firestore.batch();
      
      for (final integration in integrations) {
        final docRef = _firestore.collection(_collection).doc(integration.id);
        batch.update(docRef, integration.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update integrations: $e');
    }
  }

  /// Gets integrations that need token refresh
  Future<List<Integration>> getIntegrationsNeedingRefresh() async {
    try {
      // This would typically check for tokens that are about to expire
      // For now, we'll return integrations that haven't been updated recently
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      final query = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('updatedAt', isLessThan: cutoffDate.toIso8601String())
          .get();

      return query.docs
          .map((doc) => Integration.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get integrations needing refresh: $e');
    }
  }

  /// Searches integrations by name or type
  Future<List<Integration>> searchIntegrations(String searchTerm) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      final integrations = query.docs
          .map((doc) => Integration.fromJson(doc.data()))
          .toList();

      // Filter by search term
      return integrations.where((integration) {
        return integration.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
               integration.type.value.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    } catch (e) {
      throw Exception('Failed to search integrations: $e');
    }
  }

  /// Gets integration usage metrics
  Future<Map<String, dynamic>> getUsageMetrics(String integrationId) async {
    try {
      // This would typically track usage from a separate collection
      // For now, return basic metrics
      final integration = await getIntegrationById(integrationId);
      if (integration == null) {
        throw Exception('Integration not found: $integrationId');
      }

      return {
        'integrationId': integrationId,
        'name': integration.name,
        'type': integration.type.value,
        'isActive': integration.isActive,
        'createdAt': integration.createdAt.toIso8601String(),
        'lastUpdated': integration.updatedAt.toIso8601String(),
        'channelMappings': integration.channelMappings.length,
        // Additional metrics would be tracked separately
        'messagessent': 0,
        'lastUsed': null,
      };
    } catch (e) {
      throw Exception('Failed to get usage metrics: $e');
    }
  }
}