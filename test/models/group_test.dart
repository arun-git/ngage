import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/group.dart';
import 'package:ngage/models/enums.dart';

void main() {
  group('Group', () {
    final testGroup = Group(
      id: 'group123',
      name: 'Engineering Team',
      description: 'Software engineering team group',
      groupType: GroupType.corporate,
      settings: {'maxTeams': 10, 'allowPublicEvents': true},
      createdBy: 'member123',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    group('constructor', () {
      test('should create group with all fields', () {
        expect(testGroup.id, equals('group123'));
        expect(testGroup.name, equals('Engineering Team'));
        expect(testGroup.description, equals('Software engineering team group'));
        expect(testGroup.groupType, equals(GroupType.corporate));
        expect(testGroup.settings, equals({'maxTeams': 10, 'allowPublicEvents': true}));
        expect(testGroup.createdBy, equals('member123'));
        expect(testGroup.createdAt, equals(DateTime(2024, 1, 1)));
        expect(testGroup.updatedAt, equals(DateTime(2024, 1, 2)));
      });

      test('should create group with default empty settings', () {
        final group = Group(
          id: 'group123',
          name: 'Test Group',
          description: 'Test description',
          groupType: GroupType.social,
          createdBy: 'member123',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(group.settings, isEmpty);
      });
    });

    group('fromJson', () {
      test('should create group from JSON with all fields', () {
        final json = {
          'id': 'group123',
          'name': 'Engineering Team',
          'description': 'Software engineering team group',
          'groupType': 'corporate',
          'settings': {'maxTeams': 10, 'allowPublicEvents': true},
          'createdBy': 'member123',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T00:00:00.000Z',
        };

        final group = Group.fromJson(json);

        expect(group.id, equals('group123'));
        expect(group.name, equals('Engineering Team'));
        expect(group.groupType, equals(GroupType.corporate));
        expect(group.settings, equals({'maxTeams': 10, 'allowPublicEvents': true}));
      });

      test('should create group from JSON with null settings', () {
        final json = {
          'id': 'group123',
          'name': 'Test Group',
          'description': 'Test description',
          'groupType': 'social',
          'settings': null,
          'createdBy': 'member123',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T00:00:00.000Z',
        };

        final group = Group.fromJson(json);
        expect(group.settings, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert group to JSON', () {
        final json = testGroup.toJson();

        expect(json['id'], equals('group123'));
        expect(json['name'], equals('Engineering Team'));
        expect(json['description'], equals('Software engineering team group'));
        expect(json['groupType'], equals('corporate'));
        expect(json['settings'], equals({'maxTeams': 10, 'allowPublicEvents': true}));
        expect(json['createdBy'], equals('member123'));
        expect(json['createdAt'], equals('2024-01-01T00:00:00.000'));
        expect(json['updatedAt'], equals('2024-01-02T00:00:00.000'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedGroup = testGroup.copyWith(
          name: 'Updated Team',
          groupType: GroupType.educational,
        );

        expect(updatedGroup.id, equals(testGroup.id));
        expect(updatedGroup.name, equals('Updated Team'));
        expect(updatedGroup.groupType, equals(GroupType.educational));
        expect(updatedGroup.description, equals(testGroup.description));
        expect(updatedGroup.settings, equals(testGroup.settings));
      });
    });

    group('getSetting', () {
      test('should return setting value when exists', () {
        final maxTeams = testGroup.getSetting<int>('maxTeams');
        expect(maxTeams, equals(10));

        final allowPublic = testGroup.getSetting<bool>('allowPublicEvents');
        expect(allowPublic, isTrue);
      });

      test('should return null when setting does not exist', () {
        final nonExistent = testGroup.getSetting<String>('nonExistent');
        expect(nonExistent, isNull);
      });

      test('should return default value when setting does not exist', () {
        final nonExistent = testGroup.getSetting<String>('nonExistent', 'default');
        expect(nonExistent, equals('default'));
      });

      test('should return null when setting exists but wrong type', () {
        final wrongType = testGroup.getSetting<String>('maxTeams');
        expect(wrongType, isNull);
      });

      test('should return default when setting exists but wrong type', () {
        final wrongType = testGroup.getSetting<String>('maxTeams', 'default');
        expect(wrongType, equals('default'));
      });
    });

    group('updateSetting', () {
      test('should add new setting', () {
        final updatedGroup = testGroup.updateSetting('newSetting', 'newValue');
        
        expect(updatedGroup.getSetting<String>('newSetting'), equals('newValue'));
        expect(updatedGroup.getSetting<int>('maxTeams'), equals(10)); // Original setting preserved
      });

      test('should update existing setting', () {
        final updatedGroup = testGroup.updateSetting('maxTeams', 20);
        
        expect(updatedGroup.getSetting<int>('maxTeams'), equals(20));
        expect(updatedGroup.getSetting<bool>('allowPublicEvents'), isTrue); // Other setting preserved
      });
    });

    group('removeSetting', () {
      test('should remove existing setting', () {
        final updatedGroup = testGroup.removeSetting('maxTeams');
        
        expect(updatedGroup.getSetting<int>('maxTeams'), isNull);
        expect(updatedGroup.getSetting<bool>('allowPublicEvents'), isTrue); // Other setting preserved
      });

      test('should handle removing non-existent setting', () {
        final updatedGroup = testGroup.removeSetting('nonExistent');
        
        expect(updatedGroup.settings, equals(testGroup.settings));
      });
    });

    group('validate', () {
      test('should validate correct group data', () {
        final result = testGroup.validate();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should reject group with empty ID', () {
        final group = testGroup.copyWith(id: '');
        final result = group.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Group ID is required'));
      });

      test('should reject group with empty name', () {
        final group = testGroup.copyWith(name: '');
        final result = group.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Group name is required'));
      });

      test('should reject group with name too long', () {
        final longName = 'a' * 101;
        final group = testGroup.copyWith(name: longName);
        final result = group.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Group name must not exceed 100 characters'));
      });

      test('should reject group with empty description', () {
        final group = testGroup.copyWith(description: '');
        final result = group.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Group description is required'));
      });

      test('should reject group with description too long', () {
        final longDescription = 'a' * 1001;
        final group = testGroup.copyWith(description: longDescription);
        final result = group.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Description must not exceed 1000 characters'));
      });

      test('should reject group with empty createdBy', () {
        final group = testGroup.copyWith(createdBy: '');
        final result = group.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Created by member ID is required'));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final group1 = testGroup;
        final group2 = Group(
          id: 'group123',
          name: 'Engineering Team',
          description: 'Software engineering team group',
          groupType: GroupType.corporate,
          settings: {'maxTeams': 10, 'allowPublicEvents': true},
          createdBy: 'member123',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(group1, equals(group2));
        expect(group1.hashCode, equals(group2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final group1 = testGroup;
        final group2 = testGroup.copyWith(name: 'Different Team');

        expect(group1, isNot(equals(group2)));
      });

      test('should not be equal when settings differ', () {
        final group1 = testGroup;
        final group2 = testGroup.copyWith(settings: {'maxTeams': 20});

        expect(group1, isNot(equals(group2)));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final string = testGroup.toString();
        expect(string, contains('Group'));
        expect(string, contains('group123'));
        expect(string, contains('Engineering Team'));
        expect(string, contains('corporate'));
      });
    });
  });
}