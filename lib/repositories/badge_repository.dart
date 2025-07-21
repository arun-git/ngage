import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge.dart';
import '../models/enums.dart';

class BadgeRepository {
  final FirebaseFirestore _firestore;

  BadgeRepository(this._firestore);

  // Badge operations
  Future<Badge?> getBadge(String badgeId) async {
    try {
      final doc = await _firestore.collection('badges').doc(badgeId).get();
      if (doc.exists) {
        return Badge.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get badge: $e');
    }
  }

  Future<Badge?> getBadgeById(String badgeId) async {
    return getBadge(badgeId);
  }

  Future<void> storeMemberBadge(MemberBadge memberBadge) async {
    try {
      await _firestore.collection('member_badges').doc(memberBadge.id).set(memberBadge.toJson());
    } catch (e) {
      throw Exception('Failed to store member badge: $e');
    }
  }

  Future<void> storeMemberStreak(MemberStreak streak) async {
    try {
      await _firestore.collection('member_streaks').doc(streak.id).set(streak.toJson());
    } catch (e) {
      throw Exception('Failed to store member streak: $e');
    }
  }

  Future<MemberStreak?> getMemberStreak(String memberId, StreakType type) async {
    try {
      final snapshot = await _firestore
          .collection('member_streaks')
          .where('memberId', isEqualTo: memberId)
          .where('type', isEqualTo: type.value)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      final doc = snapshot.docs.first;
      return MemberStreak.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to get member streak: $e');
    }
  }

  Future<List<MemberStreak>> getMemberStreaks(String memberId) async {
    try {
      final snapshot = await _firestore
          .collection('member_streaks')
          .where('memberId', isEqualTo: memberId)
          .get();
      
      return snapshot.docs
          .map((doc) => MemberStreak.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get member streaks: $e');
    }
  }

  Future<MemberPoints?> getMemberPoints(String memberId) async {
    try {
      final snapshot = await _firestore
          .collection('member_points')
          .where('memberId', isEqualTo: memberId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      final doc = snapshot.docs.first;
      return MemberPoints.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to get member points: $e');
    }
  }

  Future<void> storeMemberPoints(MemberPoints points) async {
    try {
      await _firestore.collection('member_points').doc(points.id).set(points.toJson());
    } catch (e) {
      throw Exception('Failed to store member points: $e');
    }
  }

  Future<List<MemberMilestone>> getMemberMilestones(String memberId) async {
    try {
      final snapshot = await _firestore
          .collection('member_milestones')
          .where('memberId', isEqualTo: memberId)
          .get();
      
      return snapshot.docs
          .map((doc) => MemberMilestone.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get member milestones: $e');
    }
  }

  Future<void> storeMemberMilestone(MemberMilestone milestone) async {
    try {
      await _firestore.collection('member_milestones').doc(milestone.id).set(milestone.toJson());
    } catch (e) {
      throw Exception('Failed to store member milestone: $e');
    }
  }

  Future<List<Badge>> getActiveBadges() async {
    try {
      final snapshot = await _firestore
          .collection('badges')
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Badge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active badges: $e');
    }
  }

  Future<List<Badge>> getStreakMilestoneBadges(StreakType streakType) async {
    try {
      final snapshot = await _firestore
          .collection('badges')
          .where('category', isEqualTo: BadgeType.milestone.value)
          .where('criteria.streakType', isEqualTo: streakType.value)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Badge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get streak milestone badges: $e');
    }
  }

  // Member Badge operations
  Future<MemberBadge?> getMemberBadge(String memberId, String badgeId) async {
    try {
      final snapshot = await _firestore
          .collection('member_badges')
          .where('memberId', isEqualTo: memberId)
          .where('badgeId', isEqualTo: badgeId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return MemberBadge.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get member badge: $e');
    }
  }

  Future<List<MemberBadge>> getMemberBadges(String memberId) async {
    try {
      final snapshot = await _firestore
          .collection('member_badges')
          .where('memberId', isEqualTo: memberId)
          .orderBy('awardedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => MemberBadge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get member badges: $e');
    }
  }

  // Points leaderboard
  Future<List<Map<String, dynamic>>> getPointsLeaderboard({
    String? groupId,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('member_points')
          .orderBy('totalPoints', descending: true)
          .limit(limit);
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'memberId': data['memberId'],
          'totalPoints': data['totalPoints'],
          'level': data['level'],
          'levelTitle': data['levelTitle'],
          'categoryPoints': data['categoryPoints'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get points leaderboard: $e');
    }
  }
}