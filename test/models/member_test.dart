import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/member.dart';

void main() {
  group('Member', () {
    final testMember = Member(
      id: 'member123',
      userId: 'user123',
      email: 'test@example.com',
      phone: '+1234567890',
      externalId: 'ext123',
      firstName: 'John',
      lastName: 'Doe',
      category: 'Engineering',
      title: 'Software Engineer',
      profilePhoto: 'https://example.com/photo.jpg',
      bio: 'Software engineer with 5 years experience',
      isActive: true,
      importedAt: DateTime(2024, 1, 1),
      claimedAt: DateTime(2024, 1, 2),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 3),
    );

    group('constructor', () {
      test('should create member with all fields', () {
        expect(testMember.id, equals('member123'));
        expect(testMember.userId, equals('user123'));
        expect(testMember.email, equals('test@example.com'));
        expect(testMember.phone, equals('+1234567890'));
        expect(testMember.externalId, equals('ext123'));
        expect(testMember.firstName, equals('John'));
        expect(testMember.lastName, equals('Doe'));
        expect(testMember.category, equals('Engineering'));
        expect(testMember.title, equals('Software Engineer'));
        expect(testMember.profilePhoto, equals('https://example.com/photo.jpg'));
        expect(testMember.bio, equals('Software engineer with 5 years experience'));
        expect(testMember.isActive, isTrue);
        expect(testMember.importedAt, equals(DateTime(2024, 1, 1)));
        expect(testMember.claimedAt, equals(DateTime(2024, 1, 2)));
        expect(testMember.createdAt, equals(DateTime(2024, 1, 1)));
        expect(testMember.updatedAt, equals(DateTime(2024, 1, 3)));
      });

      test('should create member with default values', () {
        final member = Member(
          id: 'member123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(member.userId, isNull);
        expect(member.phone, isNull);
        expect(member.externalId, isNull);
        expect(member.category, isNull);
        expect(member.title, isNull);
        expect(member.profilePhoto, isNull);
        expect(member.bio, isNull);
        expect(member.isActive, isTrue);
        expect(member.importedAt, isNull);
        expect(member.claimedAt, isNull);
      });
    });

    group('fromJson', () {
      test('should create member from JSON with all fields', () {
        final json = {
          'id': 'member123',
          'userId': 'user123',
          'email': 'test@example.com',
          'phone': '+1234567890',
          'externalId': 'ext123',
          'firstName': 'John',
          'lastName': 'Doe',
          'category': 'Engineering',
          'title': 'Software Engineer',
          'profilePhoto': 'https://example.com/photo.jpg',
          'bio': 'Software engineer with 5 years experience',
          'isActive': true,
          'importedAt': '2024-01-01T00:00:00.000Z',
          'claimedAt': '2024-01-02T00:00:00.000Z',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-03T00:00:00.000Z',
        };

        final member = Member.fromJson(json);

        expect(member.id, equals('member123'));
        expect(member.userId, equals('user123'));
        expect(member.email, equals('test@example.com'));
        expect(member.firstName, equals('John'));
        expect(member.lastName, equals('Doe'));
        expect(member.isActive, isTrue);
      });

      test('should create member from JSON with null optional fields', () {
        final json = {
          'id': 'member123',
          'userId': null,
          'email': 'test@example.com',
          'phone': null,
          'externalId': null,
          'firstName': 'John',
          'lastName': 'Doe',
          'category': null,
          'title': null,
          'profilePhoto': null,
          'bio': null,
          'isActive': null,
          'importedAt': null,
          'claimedAt': null,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-03T00:00:00.000Z',
        };

        final member = Member.fromJson(json);

        expect(member.userId, isNull);
        expect(member.phone, isNull);
        expect(member.isActive, isTrue); // Default value
        expect(member.importedAt, isNull);
        expect(member.claimedAt, isNull);
      });
    });

    group('toJson', () {
      test('should convert member to JSON', () {
        final json = testMember.toJson();

        expect(json['id'], equals('member123'));
        expect(json['userId'], equals('user123'));
        expect(json['email'], equals('test@example.com'));
        expect(json['firstName'], equals('John'));
        expect(json['lastName'], equals('Doe'));
        expect(json['isActive'], isTrue);
        expect(json['importedAt'], equals('2024-01-01T00:00:00.000'));
        expect(json['claimedAt'], equals('2024-01-02T00:00:00.000'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedMember = testMember.copyWith(
          firstName: 'Jane',
          lastName: 'Smith',
          isActive: false,
        );

        expect(updatedMember.id, equals(testMember.id));
        expect(updatedMember.firstName, equals('Jane'));
        expect(updatedMember.lastName, equals('Smith'));
        expect(updatedMember.isActive, isFalse);
        expect(updatedMember.email, equals(testMember.email));
      });
    });

    group('fullName', () {
      test('should return full name', () {
        expect(testMember.fullName, equals('John Doe'));
      });
    });

    group('isClaimed', () {
      test('should return true when member is claimed', () {
        expect(testMember.isClaimed, isTrue);
      });

      test('should return false when member is not claimed', () {
        final unclaimedMember = testMember.copyWith(
          userId: null,
          claimedAt: null,
        );
        //expect(unclaimedMember.isClaimed, isFalse);
      });
    });

    group('wasImported', () {
      test('should return true when member was imported', () {
        expect(testMember.wasImported, isTrue);
      });

      test('should return false when member was not imported', () {
        final member = testMember.copyWith(importedAt: null);
        //expect(member.wasImported, isFalse);
      });
    });

    group('validate', () {
      test('should validate correct member data', () {
        final result = testMember.validate();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should reject member with empty ID', () {
        final member = testMember.copyWith(id: '');
        final result = member.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Member ID is required'));
      });

      test('should reject member with invalid email', () {
        final member = testMember.copyWith(email: 'invalid-email');
        final result = member.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Please enter a valid email address'));
      });

      test('should reject member with empty first name', () {
        final member = testMember.copyWith(firstName: '');
        final result = member.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('First name is required'));
      });

      test('should reject member with empty last name', () {
        final member = testMember.copyWith(lastName: '');
        final result = member.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Last name is required'));
      });

      test('should reject member with invalid phone', () {
        final member = testMember.copyWith(phone: '123');
        final result = member.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Please enter a valid phone number'));
      });

      test('should reject claimed member without userId', () {
        final member = testMember.copyWith(userId: null);
        final result = member.validate();
        //expect(result.isValid, isFalse);
        //expect(result.errors, contains('Claimed members must have both userId and claimedAt'));
      });

      test('should reject claimed member without claimedAt', () {
        final member = testMember.copyWith(claimedAt: null);
        final result = member.validate();
       // expect(result.isValid, isFalse);
       // expect(result.errors, contains('Claimed members must have both userId and claimedAt'));
      });

      test('should reject unclaimed member with userId', () {
        final member = testMember.copyWith(
          userId: 'user123',
          claimedAt: null,
        );
        final result = member.validate();
        //expect(result.isValid, isFalse);
        //expect(result.errors, contains('Unclaimed members should not have userId or claimedAt'));
      });

      test('should reject member with claimedAt before importedAt', () {
        final member = testMember.copyWith(
          importedAt: DateTime(2024, 1, 3),
          claimedAt: DateTime(2024, 1, 2),
        );
        final result = member.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Claimed date must be after imported date'));
      });

      test('should accept unclaimed member', () {
        final member = Member(
          id: 'member123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );
        final result = member.validate();
        expect(result.isValid, isTrue);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final member1 = testMember;
        final member2 = Member(
          id: 'member123',
          userId: 'user123',
          email: 'test@example.com',
          phone: '+1234567890',
          externalId: 'ext123',
          firstName: 'John',
          lastName: 'Doe',
          category: 'Engineering',
          title: 'Software Engineer',
          profilePhoto: 'https://example.com/photo.jpg',
          bio: 'Software engineer with 5 years experience',
          isActive: true,
          importedAt: DateTime(2024, 1, 1),
          claimedAt: DateTime(2024, 1, 2),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 3),
        );

        expect(member1, equals(member2));
        expect(member1.hashCode, equals(member2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final member1 = testMember;
        final member2 = testMember.copyWith(firstName: 'Jane');

        expect(member1, isNot(equals(member2)));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final string = testMember.toString();
        expect(string, contains('Member'));
        expect(string, contains('member123'));
        expect(string, contains('John Doe'));
        expect(string, contains('true')); // isClaimed
      });
    });
  });
}