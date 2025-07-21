import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/models.dart';

void main() {
  group('ScoringRubric Model Tests', () {
    late ScoringRubric testRubric;
    late List<ScoringCriterion> testCriteria;

    setUp(() {
      testCriteria = [
        ScoringCriterion(
          key: 'creativity',
          name: 'Creativity',
          description: 'Creative and innovative aspects',
          type: ScoringType.numeric,
          maxScore: 100.0,
          weight: 0.3,
          required: true,
        ),
        ScoringCriterion(
          key: 'technical',
          name: 'Technical Implementation',
          description: 'Technical quality and execution',
          type: ScoringType.numeric,
          maxScore: 100.0,
          weight: 0.4,
          required: true,
        ),
        ScoringCriterion(
          key: 'presentation',
          name: 'Presentation',
          description: 'Quality of presentation',
          type: ScoringType.scale,
          maxScore: 10.0,
          weight: 0.3,
          required: false,
          options: {'min': 1, 'max': 10},
        ),
      ];

      testRubric = ScoringRubric(
        id: 'rubric_123',
        name: 'Competition Rubric',
        description: 'Standard competition scoring rubric',
        criteria: testCriteria,
        eventId: 'event_456',
        groupId: 'group_789',
        isTemplate: false,
        createdBy: 'member_101',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        updatedAt: DateTime(2024, 1, 1, 10, 30),
      );
    });

    group('Constructor and Properties', () {
      test('should create ScoringRubric with all properties', () {
        expect(testRubric.id, equals('rubric_123'));
        expect(testRubric.name, equals('Competition Rubric'));
        expect(testRubric.description, equals('Standard competition scoring rubric'));
        expect(testRubric.criteria, hasLength(3));
        expect(testRubric.eventId, equals('event_456'));
        expect(testRubric.groupId, equals('group_789'));
        expect(testRubric.isTemplate, isFalse);
        expect(testRubric.createdBy, equals('member_101'));
        expect(testRubric.createdAt, equals(DateTime(2024, 1, 1, 10, 0)));
        expect(testRubric.updatedAt, equals(DateTime(2024, 1, 1, 10, 30)));
      });

      test('should create template rubric', () {
        final templateRubric = testRubric.copyWith(
          isTemplate: true,
          eventId: null,
          groupId: null,
        );

        expect(templateRubric.isTemplate, isTrue);
        expect(templateRubric.eventId, isNull);
        expect(templateRubric.groupId, isNull);
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = testRubric.toJson();

        expect(json['id'], equals('rubric_123'));
        expect(json['name'], equals('Competition Rubric'));
        expect(json['description'], equals('Standard competition scoring rubric'));
        expect(json['criteria'], isA<List>());
        expect(json['criteria'], hasLength(3));
        expect(json['eventId'], equals('event_456'));
        expect(json['groupId'], equals('group_789'));
        expect(json['isTemplate'], isFalse);
        expect(json['createdBy'], equals('member_101'));
        expect(json['createdAt'], equals('2024-01-01T10:00:00.000'));
        expect(json['updatedAt'], equals('2024-01-01T10:30:00.000'));
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'rubric_json',
          'name': 'JSON Rubric',
          'description': 'Test JSON rubric',
          'criteria': [
            {
              'key': 'test_criterion',
              'name': 'Test Criterion',
              'description': 'Test description',
              'type': 'numeric',
              'maxScore': 50.0,
              'weight': 1.0,
              'required': true,
              'options': null,
            }
          ],
          'eventId': 'event_json',
          'groupId': 'group_json',
          'isTemplate': true,
          'createdBy': 'member_json',
          'createdAt': '2024-01-01T10:00:00.000',
          'updatedAt': '2024-01-01T10:30:00.000',
        };

        final rubric = ScoringRubric.fromJson(json);

        expect(rubric.id, equals('rubric_json'));
        expect(rubric.name, equals('JSON Rubric'));
        expect(rubric.criteria, hasLength(1));
        expect(rubric.criteria.first.key, equals('test_criterion'));
        expect(rubric.isTemplate, isTrue);
      });

      test('should handle null values in JSON', () {
        final json = {
          'id': 'rubric_null',
          'name': 'Null Test Rubric',
          'description': 'Test with nulls',
          'criteria': null,
          'eventId': null,
          'groupId': null,
          'isTemplate': null,
          'createdBy': 'member_null',
          'createdAt': '2024-01-01T10:00:00.000',
          'updatedAt': '2024-01-01T10:30:00.000',
        };

        final rubric = ScoringRubric.fromJson(json);

        expect(rubric.criteria, isEmpty);
        expect(rubric.eventId, isNull);
        expect(rubric.groupId, isNull);
        expect(rubric.isTemplate, isFalse);
      });
    });

    group('Criterion Operations', () {
      test('should get criterion by key', () {
        final creativity = testRubric.getCriterion('creativity');
        expect(creativity, isNotNull);
        expect(creativity!.name, equals('Creativity'));

        final nonExistent = testRubric.getCriterion('nonexistent');
        expect(nonExistent, isNull);
      });

      test('should get all criterion keys', () {
        final keys = testRubric.criterionKeys;
        expect(keys, hasLength(3));
        expect(keys, contains('creativity'));
        expect(keys, contains('technical'));
        expect(keys, contains('presentation'));
      });

      test('should add criterion', () {
        final newCriterion = ScoringCriterion(
          key: 'innovation',
          name: 'Innovation',
          description: 'Innovative approach',
          maxScore: 100.0,
          weight: 0.2,
        );

        final updatedRubric = testRubric.addCriterion(newCriterion);

        expect(updatedRubric.criteria, hasLength(4));
        expect(updatedRubric.getCriterion('innovation'), isNotNull);
        expect(testRubric.criteria, hasLength(3)); // Original unchanged
      });

      test('should remove criterion', () {
        final updatedRubric = testRubric.removeCriterion('creativity');

        expect(updatedRubric.criteria, hasLength(2));
        expect(updatedRubric.getCriterion('creativity'), isNull);
        expect(updatedRubric.getCriterion('technical'), isNotNull);
        expect(testRubric.criteria, hasLength(3)); // Original unchanged
      });

      test('should update criterion', () {
        final updatedCriterion = testCriteria[0].copyWith(
          name: 'Updated Creativity',
          weight: 0.5,
        );

        final updatedRubric = testRubric.updateCriterion('creativity', updatedCriterion);

        final criterion = updatedRubric.getCriterion('creativity');
        expect(criterion!.name, equals('Updated Creativity'));
        expect(criterion.weight, equals(0.5));
        expect(testRubric.getCriterion('creativity')!.name, equals('Creativity')); // Original unchanged
      });
    });

    group('Score Calculations', () {
      test('should calculate maximum possible score', () {
        // creativity: 100, technical: 100, presentation: 10
        expect(testRubric.maxPossibleScore, equals(210.0));
      });

      test('should calculate weighted maximum score', () {
        // (100 * 0.3) + (100 * 0.4) + (10 * 0.3) = 30 + 40 + 3 = 73
        expect(testRubric.weightedMaxScore, equals(73.0));
      });

      test('should check if rubric has criteria', () {
        expect(testRubric.hasCriteria, isTrue);

        final emptyRubric = testRubric.copyWith(criteria: []);
        expect(emptyRubric.hasCriteria, isFalse);
      });
    });

    group('Validation', () {
      test('should validate valid rubric', () {
        final result = testRubric.validate();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should validate rubric with no criteria', () {
        final emptyRubric = testRubric.copyWith(criteria: []);
        final result = emptyRubric.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Scoring rubric must have at least one criterion'));
      });

      test('should validate rubric with duplicate criterion keys', () {
        final duplicateCriteria = [
          testCriteria[0],
          testCriteria[0].copyWith(name: 'Duplicate'),
        ];
        final invalidRubric = testRubric.copyWith(criteria: duplicateCriteria);
        final result = invalidRubric.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Criterion keys must be unique'));
      });

      test('should validate rubric with invalid criterion', () {
        final invalidCriteria = [
          ScoringCriterion(
            key: '', // Empty key
            name: 'Invalid',
            description: 'Invalid criterion',
            maxScore: -10.0, // Negative max score
            weight: 0.0, // Zero weight
          ),
        ];
        final invalidRubric = testRubric.copyWith(criteria: invalidCriteria);
        final result = invalidRubric.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors.any((error) => error.contains('must have a key')), isTrue);
        expect(result.errors.any((error) => error.contains('max score must be positive')), isTrue);
        expect(result.errors.any((error) => error.contains('weight must be positive')), isTrue);
      });

      test('should validate rubric name length', () {
        final longName = 'x' * 101;
        final invalidRubric = testRubric.copyWith(name: longName);
        final result = invalidRubric.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Rubric name must not exceed 100 characters'));
      });

      test('should validate rubric description length', () {
        final longDescription = 'x' * 1001;
        final invalidRubric = testRubric.copyWith(description: longDescription);
        final result = invalidRubric.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Rubric description must not exceed 1000 characters'));
      });

      test('should validate timestamp order', () {
        final invalidRubric = testRubric.copyWith(
          updatedAt: DateTime(2023, 12, 31), // Before createdAt
        );
        final result = invalidRubric.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Updated timestamp must be after or equal to creation timestamp'));
      });

      test('should validate required fields', () {
        final invalidRubric = ScoringRubric(
          id: '',
          name: '',
          description: '',
          criteria: [],
          createdBy: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final result = invalidRubric.validate();
        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThan(0));
      });
    });

    group('Equality and Hashing', () {
      test('should be equal to identical rubric', () {
        final identicalRubric = ScoringRubric(
          id: 'rubric_123',
          name: 'Competition Rubric',
          description: 'Standard competition scoring rubric',
          criteria: testCriteria,
          eventId: 'event_456',
          groupId: 'group_789',
          isTemplate: false,
          createdBy: 'member_101',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          updatedAt: DateTime(2024, 1, 1, 10, 30),
        );

        expect(testRubric, equals(identicalRubric));
        expect(testRubric.hashCode, equals(identicalRubric.hashCode));
      });

      test('should not be equal to different rubric', () {
        final differentRubric = testRubric.copyWith(name: 'Different Rubric');

        expect(testRubric, isNot(equals(differentRubric)));
      });
    });

    group('CopyWith', () {
      test('should copy with updated fields', () {
        final updatedRubric = testRubric.copyWith(
          name: 'Updated Rubric',
          isTemplate: true,
        );

        expect(updatedRubric.name, equals('Updated Rubric'));
        expect(updatedRubric.isTemplate, isTrue);
        expect(updatedRubric.id, equals(testRubric.id)); // Unchanged
        expect(updatedRubric.description, equals(testRubric.description)); // Unchanged
      });

      test('should copy without changes when no parameters provided', () {
        final copiedRubric = testRubric.copyWith();

        expect(copiedRubric, equals(testRubric));
        expect(identical(copiedRubric, testRubric), isFalse); // Different instances
      });
    });
  });

  group('ScoringCriterion Model Tests', () {
    late ScoringCriterion testCriterion;

    setUp(() {
      testCriterion = ScoringCriterion(
        key: 'creativity',
        name: 'Creativity',
        description: 'Creative and innovative aspects',
        type: ScoringType.numeric,
        maxScore: 100.0,
        weight: 0.3,
        required: true,
        options: {'min': 0, 'max': 100},
      );
    });

    group('Constructor and Properties', () {
      test('should create ScoringCriterion with all properties', () {
        expect(testCriterion.key, equals('creativity'));
        expect(testCriterion.name, equals('Creativity'));
        expect(testCriterion.description, equals('Creative and innovative aspects'));
        expect(testCriterion.type, equals(ScoringType.numeric));
        expect(testCriterion.maxScore, equals(100.0));
        expect(testCriterion.weight, equals(0.3));
        expect(testCriterion.required, isTrue);
        expect(testCriterion.options, isNotNull);
      });

      test('should create ScoringCriterion with default values', () {
        final defaultCriterion = ScoringCriterion(
          key: 'test',
          name: 'Test',
          description: 'Test criterion',
        );

        expect(defaultCriterion.type, equals(ScoringType.numeric));
        expect(defaultCriterion.maxScore, equals(100.0));
        expect(defaultCriterion.weight, equals(1.0));
        expect(defaultCriterion.required, isTrue);
        expect(defaultCriterion.options, isNull);
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = testCriterion.toJson();

        expect(json['key'], equals('creativity'));
        expect(json['name'], equals('Creativity'));
        expect(json['description'], equals('Creative and innovative aspects'));
        expect(json['type'], equals('numeric'));
        expect(json['maxScore'], equals(100.0));
        expect(json['weight'], equals(0.3));
        expect(json['required'], isTrue);
        expect(json['options'], isA<Map<String, dynamic>>());
      });

      test('should create from JSON correctly', () {
        final json = {
          'key': 'technical',
          'name': 'Technical',
          'description': 'Technical implementation',
          'type': 'scale',
          'maxScore': 50.0,
          'weight': 0.4,
          'required': false,
          'options': {'min': 1, 'max': 5},
        };

        final criterion = ScoringCriterion.fromJson(json);

        expect(criterion.key, equals('technical'));
        expect(criterion.name, equals('Technical'));
        expect(criterion.type, equals(ScoringType.scale));
        expect(criterion.maxScore, equals(50.0));
        expect(criterion.weight, equals(0.4));
        expect(criterion.required, isFalse);
        expect(criterion.options!['min'], equals(1));
        expect(criterion.options!['max'], equals(5));
      });

      test('should handle null values in JSON', () {
        final json = {
          'key': 'test',
          'name': 'Test',
          'description': 'Test description',
          'type': null,
          'maxScore': null,
          'weight': null,
          'required': null,
          'options': null,
        };

        final criterion = ScoringCriterion.fromJson(json);

        expect(criterion.type, equals(ScoringType.numeric));
        expect(criterion.maxScore, equals(100.0));
        expect(criterion.weight, equals(1.0));
        expect(criterion.required, isTrue);
        expect(criterion.options, isNull);
      });
    });

    group('Score Validation', () {
      test('should validate numeric scores', () {
        expect(testCriterion.isValidScore(50.0), isTrue);
        expect(testCriterion.isValidScore(0.0), isTrue);
        expect(testCriterion.isValidScore(100.0), isTrue);
        expect(testCriterion.isValidScore(150.0), isFalse);
        expect(testCriterion.isValidScore(-10.0), isFalse);
        expect(testCriterion.isValidScore('not a number'), isFalse);
      });

      test('should validate scale scores', () {
        final scaleCriterion = testCriterion.copyWith(
          type: ScoringType.scale,
          options: {'min': 1, 'max': 5},
        );

        expect(scaleCriterion.isValidScore(3.0), isTrue);
        expect(scaleCriterion.isValidScore(1.0), isTrue);
        expect(scaleCriterion.isValidScore(5.0), isTrue);
        expect(scaleCriterion.isValidScore(0.0), isFalse);
        expect(scaleCriterion.isValidScore(6.0), isFalse);
      });

      test('should validate boolean scores', () {
        final booleanCriterion = testCriterion.copyWith(
          type: ScoringType.boolean,
        );

        expect(booleanCriterion.isValidScore(true), isTrue);
        expect(booleanCriterion.isValidScore(false), isTrue);
        expect(booleanCriterion.isValidScore(1), isFalse);
        expect(booleanCriterion.isValidScore('true'), isFalse);
      });
    });

    group('Equality and Hashing', () {
      test('should be equal to identical criterion', () {
        final identicalCriterion = ScoringCriterion(
          key: 'creativity',
          name: 'Creativity',
          description: 'Creative and innovative aspects',
          type: ScoringType.numeric,
          maxScore: 100.0,
          weight: 0.3,
          required: true,
          options: {'min': 0, 'max': 100},
        );

        expect(testCriterion, equals(identicalCriterion));
        expect(testCriterion.hashCode, equals(identicalCriterion.hashCode));
      });

      test('should not be equal to different criterion', () {
        final differentCriterion = testCriterion.copyWith(weight: 0.5);

        expect(testCriterion, isNot(equals(differentCriterion)));
      });
    });

    group('CopyWith', () {
      test('should copy with updated fields', () {
        final updatedCriterion = testCriterion.copyWith(
          name: 'Updated Creativity',
          weight: 0.5,
        );

        expect(updatedCriterion.name, equals('Updated Creativity'));
        expect(updatedCriterion.weight, equals(0.5));
        expect(updatedCriterion.key, equals(testCriterion.key)); // Unchanged
        expect(updatedCriterion.type, equals(testCriterion.type)); // Unchanged
      });

      test('should copy without changes when no parameters provided', () {
        final copiedCriterion = testCriterion.copyWith();

        expect(copiedCriterion, equals(testCriterion));
        expect(identical(copiedCriterion, testCriterion), isFalse); // Different instances
      });
    });
  });
}