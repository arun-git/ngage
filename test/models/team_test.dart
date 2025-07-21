import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/team.dart';

void main() {
  group('Team', () {
    final testTeam = Team(
      id: 'team123',
      groupId: 'group123',
      name: 'Alpha Team',
      description: 'The best team in the group',
      teamLeadId: 'member123',
      memberIds: ['member123', 'member456', 'member789'],
      maxMembers: 5,
      teamType: 'development',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    group('constructor', () {
      test('should create team with all fields', () {
        expect(testTeam.id, equals('team123'));
        expect(testTeam.groupId, equals('group123'));
        expect(testTeam.name, equals('Alpha Team'));
        expect(testTeam.description, equals('The best team in the group'));
        expect(testTeam.teamLeadId, equals('member123'));
        expect(testTeam.memberIds, equals(['member123', 'member456', 'member789']));
        expect(testTeam.maxMembers, equals(5));
        expect(testTeam.teamType, equals('development'));
        expect(testTeam.isActive, isTrue);
        expect(testTeam.createdAt, equals(DateTime(2024, 1, 1)));
        expect(testTeam.updatedAt, equals(DateTime(2024, 1, 2)));
      });

      test('should create team with default values', () {
        final team = Team(
          id: 'team123',
          groupId: 'group123',
          name: 'Test Team',
          description: 'Test description',
          teamLeadId: 'member123',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(team.memberIds, isEmpty);
        expect(team.maxMembers, isNull);
        expect(team.teamType, isNull);
        expect(team.isActive, isTrue);
      });
    });

    group('fromJson', () {
      test('should create team from JSON with all fields', () {
        final json = {
          'id': 'team123',
          'groupId': 'group123',
          'name': 'Alpha Team',
          'description': 'The best team in the group',
          'teamLeadId': 'member123',
          'memberIds': ['member123', 'member456', 'member789'],
          'maxMembers': 5,
          'teamType': 'development',
          'isActive': true,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T00:00:00.000Z',
        };

        final team = Team.fromJson(json);

        expect(team.id, equals('team123'));
        expect(team.name, equals('Alpha Team'));
        expect(team.memberIds, equals(['member123', 'member456', 'member789']));
        expect(team.maxMembers, equals(5));
      });

      test('should create team from JSON with null optional fields', () {
        final json = {
          'id': 'team123',
          'groupId': 'group123',
          'name': 'Test Team',
          'description': 'Test description',
          'teamLeadId': 'member123',
          'memberIds': null,
          'maxMembers': null,
          'teamType': null,
          'isActive': null,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T00:00:00.000Z',
        };

        final team = Team.fromJson(json);

        expect(team.memberIds, isEmpty);
        expect(team.maxMembers, isNull);
        expect(team.teamType, isNull);
        expect(team.isActive, isTrue); // Default value
      });
    });

    group('toJson', () {
      test('should convert team to JSON', () {
        final json = testTeam.toJson();

        expect(json['id'], equals('team123'));
        expect(json['groupId'], equals('group123'));
        expect(json['name'], equals('Alpha Team'));
        expect(json['description'], equals('The best team in the group'));
        expect(json['teamLeadId'], equals('member123'));
        expect(json['memberIds'], equals(['member123', 'member456', 'member789']));
        expect(json['maxMembers'], equals(5));
        expect(json['teamType'], equals('development'));
        expect(json['isActive'], isTrue);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedTeam = testTeam.copyWith(
          name: 'Beta Team',
          maxMembers: 10,
          isActive: false,
        );

        expect(updatedTeam.id, equals(testTeam.id));
        expect(updatedTeam.name, equals('Beta Team'));
        expect(updatedTeam.maxMembers, equals(10));
        expect(updatedTeam.isActive, isFalse);
        expect(updatedTeam.memberIds, equals(testTeam.memberIds));
      });
    });

    group('memberCount', () {
      test('should return correct member count', () {
        expect(testTeam.memberCount, equals(3));
      });

      test('should return zero for empty team', () {
        final emptyTeam = testTeam.copyWith(memberIds: []);
        expect(emptyTeam.memberCount, equals(0));
      });
    });

    group('isAtCapacity', () {
      test('should return false when below capacity', () {
        expect(testTeam.isAtCapacity, isFalse);
      });

      test('should return true when at capacity', () {
        final fullTeam = testTeam.copyWith(
          memberIds: ['member1', 'member2', 'member3', 'member4', 'member5'],
        );
        expect(fullTeam.isAtCapacity, isTrue);
      });

      test('should return false when no max members set', () {
        final noMaxTeam = testTeam.copyWith(maxMembers: null);
        expect(noMaxTeam.isAtCapacity, isFalse);
      });
    });

    group('canAcceptMembers', () {
      test('should return true when below capacity', () {
        expect(testTeam.canAcceptMembers, isTrue);
      });

      test('should return false when at capacity', () {
        final fullTeam = testTeam.copyWith(
          memberIds: ['member1', 'member2', 'member3', 'member4', 'member5'],
        );
        expect(fullTeam.canAcceptMembers, isFalse);
      });
    });

    group('hasMember', () {
      test('should return true for existing member', () {
        expect(testTeam.hasMember('member123'), isTrue);
        expect(testTeam.hasMember('member456'), isTrue);
      });

      test('should return false for non-existing member', () {
        expect(testTeam.hasMember('nonexistent'), isFalse);
      });
    });

    group('isTeamLead', () {
      test('should return true for team lead', () {
        expect(testTeam.isTeamLead('member123'), isTrue);
      });

      test('should return false for non-team lead', () {
        expect(testTeam.isTeamLead('member456'), isFalse);
      });
    });

    group('addMember', () {
      test('should add new member', () {
        final updatedTeam = testTeam.addMember('newMember');
        
        expect(updatedTeam.memberIds, contains('newMember'));
        expect(updatedTeam.memberCount, equals(4));
      });

      test('should not add existing member', () {
        final updatedTeam = testTeam.addMember('member123');
        
        expect(updatedTeam.memberIds, equals(testTeam.memberIds));
        expect(updatedTeam.memberCount, equals(testTeam.memberCount));
      });

      test('should throw error when at capacity', () {
        final fullTeam = testTeam.copyWith(
          memberIds: ['member1', 'member2', 'member3', 'member4', 'member5'],
        );
        
        expect(
          () => fullTeam.addMember('newMember'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('removeMember', () {
      test('should remove existing member', () {
        final updatedTeam = testTeam.removeMember('member456');
        
        expect(updatedTeam.memberIds, isNot(contains('member456')));
        expect(updatedTeam.memberCount, equals(2));
      });

      test('should not change team when removing non-existing member', () {
        final updatedTeam = testTeam.removeMember('nonexistent');
        
        expect(updatedTeam.memberIds, equals(testTeam.memberIds));
      });

      test('should throw error when trying to remove team lead', () {
        expect(
          () => testTeam.removeMember('member123'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('changeTeamLead', () {
      test('should change team lead to existing member', () {
        final updatedTeam = testTeam.changeTeamLead('member456');
        
        expect(updatedTeam.teamLeadId, equals('member456'));
      });

      test('should throw error when new lead is not a member', () {
        expect(
          () => testTeam.changeTeamLead('nonexistent'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('validate', () {
      test('should validate correct team data', () {
        final result = testTeam.validate();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should reject team with empty ID', () {
        final team = testTeam.copyWith(id: '');
        final result = team.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Team ID is required'));
      });

      test('should reject team with empty name', () {
        final team = testTeam.copyWith(name: '');
        final result = team.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Team name is required'));
      });

      test('should reject team with name too long', () {
        final longName = 'a' * 101;
        final team = testTeam.copyWith(name: longName);
        final result = team.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Team name must not exceed 100 characters'));
      });

      test('should reject team with empty description', () {
        final team = testTeam.copyWith(description: '');
        final result = team.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Team description is required'));
      });

      test('should reject team when team lead is not a member', () {
        final team = testTeam.copyWith(
          teamLeadId: 'nonexistent',
          memberIds: ['member456', 'member789'],
        );
        final result = team.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Team lead must be a member of the team'));
      });

      test('should reject team with invalid max members', () {
        final team = testTeam.copyWith(maxMembers: 0);
        final result = team.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Maximum members must be at least 1'));
      });

      test('should reject team with more members than max allowed', () {
        final team = testTeam.copyWith(maxMembers: 2);
        final result = team.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Team has more members than maximum allowed'));
      });

      test('should reject team with duplicate members', () {
        final team = testTeam.copyWith(
          memberIds: ['member123', 'member456', 'member123'],
        );
        final result = team.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Team cannot have duplicate members'));
      });

      test('should reject team with team type too long', () {
        final longType = 'a' * 51;
        final team = testTeam.copyWith(teamType: longType);
        final result = team.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Team type must not exceed 50 characters'));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final team1 = testTeam;
        final team2 = Team(
          id: 'team123',
          groupId: 'group123',
          name: 'Alpha Team',
          description: 'The best team in the group',
          teamLeadId: 'member123',
          memberIds: ['member123', 'member456', 'member789'],
          maxMembers: 5,
          teamType: 'development',
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(team1, equals(team2));
        expect(team1.hashCode, equals(team2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final team1 = testTeam;
        final team2 = testTeam.copyWith(name: 'Beta Team');

        expect(team1, isNot(equals(team2)));
      });

      test('should not be equal when member lists differ', () {
        final team1 = testTeam;
        final team2 = testTeam.copyWith(memberIds: ['member123', 'member456']);

        expect(team1, isNot(equals(team2)));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final string = testTeam.toString();
        expect(string, contains('Team'));
        expect(string, contains('team123'));
        expect(string, contains('Alpha Team'));
        expect(string, contains('memberCount: 3'));
      });
    });
  });
}