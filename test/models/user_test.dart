import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/user.dart';

void main() {
  group('User', () {
    final testUser = User(
      id: 'user123',
      email: 'test@example.com',
      phone: '+1234567890',
      defaultMember: 'member123',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    group('constructor', () {
      test('should create user with all fields', () {
        expect(testUser.id, equals('user123'));
        expect(testUser.email, equals('test@example.com'));
        expect(testUser.phone, equals('+1234567890'));
        expect(testUser.defaultMember, equals('member123'));
        expect(testUser.createdAt, equals(DateTime(2024, 1, 1)));
        expect(testUser.updatedAt, equals(DateTime(2024, 1, 2)));
      });

      test('should create user with optional fields as null', () {
        final user = User(
          id: 'user123',
          email: 'test@example.com',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(user.phone, isNull);
        expect(user.defaultMember, isNull);
      });
    });

    group('fromJson', () {
      test('should create user from JSON with all fields', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'phone': '+1234567890',
          'defaultMember': 'member123',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T00:00:00.000Z',
        };

        final user = User.fromJson(json);

        expect(user.id, equals('user123'));
        expect(user.email, equals('test@example.com'));
        expect(user.phone, equals('+1234567890'));
        expect(user.defaultMember, equals('member123'));
        expect(user.createdAt, equals(DateTime.parse('2024-01-01T00:00:00.000Z')));
        expect(user.updatedAt, equals(DateTime.parse('2024-01-02T00:00:00.000Z')));
      });

      test('should create user from JSON with null optional fields', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'phone': null,
          'defaultMember': null,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T00:00:00.000Z',
        };

        final user = User.fromJson(json);

        expect(user.phone, isNull);
        expect(user.defaultMember, isNull);
      });
    });

    group('toJson', () {
      test('should convert user to JSON with all fields', () {
        final json = testUser.toJson();

        expect(json['id'], equals('user123'));
        expect(json['email'], equals('test@example.com'));
        expect(json['phone'], equals('+1234567890'));
        expect(json['defaultMember'], equals('member123'));
        expect(json['createdAt'], equals('2024-01-01T00:00:00.000'));
        expect(json['updatedAt'], equals('2024-01-02T00:00:00.000'));
      });

      test('should convert user to JSON with null optional fields', () {
        final user = User(
          id: 'user123',
          email: 'test@example.com',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        final json = user.toJson();

        expect(json['phone'], isNull);
        expect(json['defaultMember'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedUser = testUser.copyWith(
          email: 'updated@example.com',
          phone: '+9876543210',
        );

        expect(updatedUser.id, equals(testUser.id));
        expect(updatedUser.email, equals('updated@example.com'));
        expect(updatedUser.phone, equals('+9876543210'));
        expect(updatedUser.defaultMember, equals(testUser.defaultMember));
        expect(updatedUser.createdAt, equals(testUser.createdAt));
        expect(updatedUser.updatedAt, equals(testUser.updatedAt));
      });

      test('should create copy with no changes when no parameters provided', () {
        final copiedUser = testUser.copyWith();

        expect(copiedUser.id, equals(testUser.id));
        expect(copiedUser.email, equals(testUser.email));
        expect(copiedUser.phone, equals(testUser.phone));
        expect(copiedUser.defaultMember, equals(testUser.defaultMember));
        expect(copiedUser.createdAt, equals(testUser.createdAt));
        expect(copiedUser.updatedAt, equals(testUser.updatedAt));
      });
    });

    group('validate', () {
      test('should validate correct user data', () {
        final result = testUser.validate();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should reject user with empty ID', () {
        final user = testUser.copyWith(id: '');
        final result = user.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('User ID is required'));
      });

      test('should reject user with invalid email', () {
        final user = testUser.copyWith(email: 'invalid-email');
        final result = user.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Please enter a valid email address'));
      });

      test('should reject user with invalid phone', () {
        final user = testUser.copyWith(phone: '123');
        final result = user.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Please enter a valid phone number'));
      });

      test('should accept user with null phone', () {
        final user = testUser.copyWith(phone: null);
        final result = user.validate();
        expect(result.isValid, isTrue);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final user1 = testUser;
        final user2 = User(
          id: 'user123',
          email: 'test@example.com',
          phone: '+1234567890',
          defaultMember: 'member123',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final user1 = testUser;
        final user2 = testUser.copyWith(email: 'different@example.com');

        expect(user1, isNot(equals(user2)));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final string = testUser.toString();
        expect(string, contains('User'));
        expect(string, contains('user123'));
        expect(string, contains('test@example.com'));
      });
    });
  });
}