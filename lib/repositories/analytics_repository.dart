import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics.dart';
import '../models/enums.dart';

class AnalyticsRepository {
  final FirebaseFirestore _firestore;

  AnalyticsRepository(this._firestore);

  /// Get member participation data
  Future<Map<String, dynamic>> getMemberParticipationData({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get all group members
      final groupMembersQuery = await _firestore
          .collection('group_members')
          .where('groupId', isEqualTo: groupId)
          .get();

      final totalMembers = groupMembersQuery.docs.length;

      // Get active members (those who have participated in events or social activities)
      final activeMemberIds = <String>{};
      final membersByCategory = <String, int>{};

      // Check for event participation
      final submissionsQuery = await _firestore
          .collection('submissions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (final doc in submissionsQuery.docs) {
        final submittedBy = doc.data()['submittedBy'] as String?;
        if (submittedBy != null) {
          activeMemberIds.add(submittedBy);
        }
      }

      // Check for social activity (posts, likes, comments)
      final postsQuery = await _firestore
          .collection('posts')
          .where('groupId', isEqualTo: groupId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (final doc in postsQuery.docs) {
        final authorId = doc.data()['authorId'] as String?;
        if (authorId != null) {
          activeMemberIds.add(authorId);
        }
      }

      // Get member categories
      for (final memberDoc in groupMembersQuery.docs) {
        final memberId = memberDoc.data()['memberId'] as String;
        final memberQuery = await _firestore
            .collection('members')
            .doc(memberId)
            .get();
        
        if (memberQuery.exists) {
          final category = memberQuery.data()?['category'] as String? ?? 'Uncategorized';
          membersByCategory[category] = (membersByCategory[category] ?? 0) + 1;
        }
      }

      return {
        'total': totalMembers,
        'active': activeMemberIds.length,
        'byCategory': membersByCategory,
      };
    } catch (e) {
      throw Exception('Failed to get member participation data: $e');
    }
  }

  /// Get team participation data
  Future<Map<String, dynamic>> getTeamParticipationData({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get all teams in the group
      final teamsQuery = await _firestore
          .collection('teams')
          .where('groupId', isEqualTo: groupId)
          .get();

      final totalTeams = teamsQuery.docs.length;
      final activeTeamIds = <String>{};
      final teamsByType = <String, int>{};

      // Check for team activity (submissions)
      final submissionsQuery = await _firestore
          .collection('submissions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (final doc in submissionsQuery.docs) {
        final teamId = doc.data()['teamId'] as String?;
        if (teamId != null) {
          activeTeamIds.add(teamId);
        }
      }

      // Get team types
      for (final teamDoc in teamsQuery.docs) {
        final teamType = teamDoc.data()['teamType'] as String? ?? 'General';
        teamsByType[teamType] = (teamsByType[teamType] ?? 0) + 1;
      }

      return {
        'total': totalTeams,
        'active': activeTeamIds.length,
        'byType': teamsByType,
      };
    } catch (e) {
      throw Exception('Failed to get team participation data: $e');
    }
  }

  /// Get event participation data
  Future<Map<String, dynamic>> getEventParticipationData({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    String? eventId,
  }) async {
    try {
      Query eventsQuery = _firestore
          .collection('events')
          .where('groupId', isEqualTo: groupId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (eventId != null) {
        eventsQuery = eventsQuery.where(FieldPath.documentId, isEqualTo: eventId);
      }

      final eventsSnapshot = await eventsQuery.get();
      final totalEvents = eventsSnapshot.docs.length;

      int completedEvents = 0;
      for (final doc in eventsSnapshot.docs) {
        final status = doc.data() as Map<String, dynamic>;
        if (status['status'] == 'completed') {
          completedEvents++;
        }
      }

      return {
        'total': totalEvents,
        'completed': completedEvents,
      };
    } catch (e) {
      throw Exception('Failed to get event participation data: $e');
    }
  }

  /// Get submission data
  Future<Map<String, dynamic>> getSubmissionData({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    String? eventId,
  }) async {
    try {
      // Get events in the group to filter submissions
      final eventsQuery = await _firestore
          .collection('events')
          .where('groupId', isEqualTo: groupId)
          .get();

      final eventIds = eventsQuery.docs.map((doc) => doc.id).toList();

      if (eventIds.isEmpty) {
        return {'total': 0};
      }

      Query submissionsQuery = _firestore
          .collection('submissions')
          .where('eventId', whereIn: eventIds)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (eventId != null) {
        submissionsQuery = submissionsQuery.where('eventId', isEqualTo: eventId);
      }

      final submissionsSnapshot = await submissionsQuery.get();

      return {
        'total': submissionsSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get submission data: $e');
    }
  }

  /// Get judge activity data
  Future<Map<String, dynamic>> getJudgeActivityData({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    String? eventId,
  }) async {
    try {
      // Get judges in the group
      final judgesQuery = await _firestore
          .collection('group_members')
          .where('groupId', isEqualTo: groupId)
          .where('role', isEqualTo: 'judge')
          .get();

      final totalJudges = judgesQuery.docs.length;
      final activeJudgeIds = <String>{};

      // Check for scoring activity
      final scoresQuery = await _firestore
          .collection('scores')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (final doc in scoresQuery.docs) {
        final judgeId = doc.data()['judgeId'] as String?;
        if (judgeId != null) {
          activeJudgeIds.add(judgeId);
        }
      }

      return {
        'total': totalJudges,
        'active': activeJudgeIds.length,
      };
    } catch (e) {
      throw Exception('Failed to get judge activity data: $e');
    }
  }

  /// Get scoring data
  Future<Map<String, dynamic>> getScoringData({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    String? eventId,
  }) async {
    try {
      // Get events in the group
      final eventsQuery = await _firestore
          .collection('events')
          .where('groupId', isEqualTo: groupId)
          .get();

      final eventIds = eventsQuery.docs.map((doc) => doc.id).toList();

      if (eventIds.isEmpty) {
        return {
          'total': 0,
          'byJudge': <String, int>{},
          'averageByEvent': <String, double>{},
        };
      }

      // Get submissions for these events
      final submissionsQuery = await _firestore
          .collection('submissions')
          .where('eventId', whereIn: eventIds)
          .get();

      final submissionIds = submissionsQuery.docs.map((doc) => doc.id).toList();

      if (submissionIds.isEmpty) {
        return {
          'total': 0,
          'byJudge': <String, int>{},
          'averageByEvent': <String, double>{},
        };
      }

      // Get scores for these submissions
      Query scoresQuery = _firestore
          .collection('scores')
          .where('submissionId', whereIn: submissionIds)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      final scoresSnapshot = await scoresQuery.get();
      final scoresByJudge = <String, int>{};
      final scoresByEvent = <String, List<double>>{};

      for (final doc in scoresSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final judgeId = data['judgeId'] as String;
        final scores = data['scores'] as Map<String, dynamic>? ?? {};
        
        // Count scores by judge
        scoresByJudge[judgeId] = (scoresByJudge[judgeId] ?? 0) + 1;

        // Calculate average score for this submission
        if (scores.isNotEmpty) {
          final numericScores = scores.values
              .where((v) => v is num)
              .map((v) => (v as num).toDouble())
              .toList();
          
          if (numericScores.isNotEmpty) {
            final avgScore = numericScores.reduce((a, b) => a + b) / numericScores.length;
            
            // Find the event for this submission
            final submissionId = data['submissionId'] as String;
            final submission = submissionsQuery.docs
                .firstWhere((s) => s.id == submissionId);
            final eventId = submission.data()['eventId'] as String;
            
            scoresByEvent[eventId] = scoresByEvent[eventId] ?? [];
            scoresByEvent[eventId]!.add(avgScore);
          }
        }
      }

      // Calculate average scores by event
      final averageByEvent = <String, double>{};
      scoresByEvent.forEach((eventId, scores) {
        if (scores.isNotEmpty) {
          averageByEvent[eventId] = scores.reduce((a, b) => a + b) / scores.length;
        }
      });

      return {
        'total': scoresSnapshot.docs.length,
        'byJudge': scoresByJudge,
        'averageByEvent': averageByEvent,
      };
    } catch (e) {
      throw Exception('Failed to get scoring data: $e');
    }
  }

  /// Get judge comment data
  Future<Map<String, dynamic>> getJudgeCommentData({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    String? eventId,
  }) async {
    try {
      // Get events in the group
      final eventsQuery = await _firestore
          .collection('events')
          .where('groupId', isEqualTo: groupId)
          .get();

      final eventIds = eventsQuery.docs.map((doc) => doc.id).toList();

      if (eventIds.isEmpty) {
        return {
          'total': 0,
          'byJudge': <String, int>{},
        };
      }

      // Get submissions for these events
      final submissionsQuery = await _firestore
          .collection('submissions')
          .where('eventId', whereIn: eventIds)
          .get();

      final submissionIds = submissionsQuery.docs.map((doc) => doc.id).toList();

      if (submissionIds.isEmpty) {
        return {
          'total': 0,
          'byJudge': <String, int>{},
        };
      }

      // Get judge comments
      Query commentsQuery = _firestore
          .collection('judge_comments')
          .where('submissionId', whereIn: submissionIds)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      final commentsSnapshot = await commentsQuery.get();
      final commentsByJudge = <String, int>{};

      for (final doc in commentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
        final judgeId = data['judgeId'] as String?;
        if (judgeId != null) {
          commentsByJudge[judgeId] = (commentsByJudge[judgeId] ?? 0) + 1;
        }
          }
      }

      return {
        'total': commentsSnapshot.docs.length,
        'byJudge': commentsByJudge,
      };
    } catch (e) {
      throw Exception('Failed to get judge comment data: $e');
    }
  }

  /// Get post data for engagement metrics
  Future<Map<String, dynamic>> getPostData({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final postsQuery = await _firestore
          .collection('posts')
          .where('groupId', isEqualTo: groupId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final postsByMember = <String, int>{};

      for (final doc in postsQuery.docs) {
        final authorId = doc.data()['authorId'] as String;
        postsByMember[authorId] = (postsByMember[authorId] ?? 0) + 1;
      }

      return {
        'total': postsQuery.docs.length,
        'byMember': postsByMember,
      };
    } catch (e) {
      throw Exception('Failed to get post data: $e');
    }
  }

  /// Get like data for engagement metrics
  Future<Map<String, dynamic>> getLikeData({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get posts in the group first
      final postsQuery = await _firestore
          .collection('posts')
          .where('groupId', isEqualTo: groupId)
          .get();

      final postIds = postsQuery.docs.map((doc) => doc.id).toList();

      if (postIds.isEmpty) {
        return {
          'total': 0,
          'byMember': <String, int>{},
        };
      }

      // Get likes for these posts
      final likesQuery = await _firestore
          .collection('post_likes')
          .where('postId', whereIn: postIds)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final likesByMember = <String, int>{};

      for (final doc in likesQuery.docs) {
        final memberId = doc.data()['memberId'] as String;
        likesByMember[memberId] = (likesByMember[memberId] ?? 0) + 1;
      }

      return {
        'total': likesQuery.docs.length,
        'byMember': likesByMember,
      };
    } catch (e) {
      throw Exception('Failed to get like data: $e');
    }
  }

  /// Get comment data for engagement metrics
  Future<Map<String, dynamic>> getCommentData({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get posts in the group first
      final postsQuery = await _firestore
          .collection('posts')
          .where('groupId', isEqualTo: groupId)
          .get();

      final postIds = postsQuery.docs.map((doc) => doc.id).toList();

      if (postIds.isEmpty) {
        return {
          'total': 0,
          'byMember': <String, int>{},
        };
      }

      // Get comments for these posts
      final commentsQuery = await _firestore
          .collection('post_comments')
          .where('postId', whereIn: postIds)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final commentsByMember = <String, int>{};

      for (final doc in commentsQuery.docs) {
        final authorId = doc.data()['authorId'] as String;
        commentsByMember[authorId] = (commentsByMember[authorId] ?? 0) + 1;
      }

      return {
        'total': commentsQuery.docs.length,
        'byMember': commentsByMember,
      };
    } catch (e) {
      throw Exception('Failed to get comment data: $e');
    }
  }

  /// Get top contributors
  Future<List<String>> getTopContributors({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final contributorScores = <String, int>{};

      // Get post contributions
      final postData = await getPostData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );
      final postsByMember = postData['byMember'] as Map<String, int>;

      // Get like contributions
      final likeData = await getLikeData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );
      final likesByMember = likeData['byMember'] as Map<String, int>;

      // Get comment contributions
      final commentData = await getCommentData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );
      final commentsByMember = commentData['byMember'] as Map<String, int>;

      // Calculate total contribution scores
      final allMemberIds = <String>{
        ...postsByMember.keys,
        ...likesByMember.keys,
        ...commentsByMember.keys,
      };

      for (final memberId in allMemberIds) {
        final postScore = (postsByMember[memberId] ?? 0) * 3; // Posts worth more
        final likeScore = likesByMember[memberId] ?? 0;
        final commentScore = (commentsByMember[memberId] ?? 0) * 2; // Comments worth more than likes
        
        contributorScores[memberId] = postScore + likeScore + commentScore;
      }

      // Sort by score and return top contributors
      final sortedContributors = contributorScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedContributors
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      throw Exception('Failed to get top contributors: $e');
    }
  }

  /// Get engagement by day
  Future<Map<String, double>> getEngagementByDay({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final engagementByDay = <String, double>{};
      
      // Initialize all days with 0
      var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
      
      while (currentDate.isBefore(endDateOnly) || currentDate.isAtSameMomentAs(endDateOnly)) {
        final dateKey = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
        engagementByDay[dateKey] = 0.0;
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Get daily post counts
      final postsQuery = await _firestore
          .collection('posts')
          .where('groupId', isEqualTo: groupId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (final doc in postsQuery.docs) {
        final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
        final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        engagementByDay[dateKey] = (engagementByDay[dateKey] ?? 0) + 3.0; // Posts worth 3 points
      }

      // Add likes and comments (simplified - would need to get post IDs first in real implementation)
      // For now, we'll estimate based on posts
      engagementByDay.forEach((date, score) {
        if (score > 0) {
          engagementByDay[date] = score * 1.5; // Estimate additional engagement
        }
      });

      return engagementByDay;
    } catch (e) {
      throw Exception('Failed to get engagement by day: $e');
    }
  }

  /// Store analytics metrics
  Future<void> storeAnalyticsMetrics(AnalyticsMetrics metrics) async {
    try {
      await _firestore
          .collection('analytics_metrics')
          .doc(metrics.id)
          .set(metrics.toJson());
    } catch (e) {
      throw Exception('Failed to store analytics metrics: $e');
    }
  }

  /// Store analytics report
  Future<void> storeAnalyticsReport(AnalyticsReport report) async {
    try {
      await _firestore
          .collection('analytics_reports')
          .doc(report.id)
          .set(report.toJson());
    } catch (e) {
      throw Exception('Failed to store analytics report: $e');
    }
  }

  /// Get historical metrics
  Future<List<AnalyticsMetrics>> getHistoricalMetrics({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    AnalyticsPeriod period = AnalyticsPeriod.monthly,
    String? eventId,
  }) async {
    try {
      Query query = _firestore
          .collection('analytics_metrics')
          .where('groupId', isEqualTo: groupId)
          .where('periodStart', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('periodEnd', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('periodStart');

      if (eventId != null) {
        query = query.where('eventId', isEqualTo: eventId);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => AnalyticsMetrics.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get historical metrics: $e');
    }
  }

  /// Get analytics reports
  Future<List<AnalyticsReport>> getAnalyticsReports({
    List<String>? groupIds,
    DateTime? startDate,
    DateTime? endDate,
    String? generatedBy,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('analytics_reports')
          .orderBy('generatedAt', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('generatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('generatedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (generatedBy != null) {
        query = query.where('generatedBy', isEqualTo: generatedBy);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => AnalyticsReport.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get analytics reports: $e');
    }
  }
}