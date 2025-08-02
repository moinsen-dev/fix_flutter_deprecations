import 'package:fix_flutter_deprecations/src/models/models.dart';
import 'package:test/test.dart';

void main() {
  group('FixResult', () {
    test('creates instance with required parameters', () {
      const result = FixResult(
        filePath: '/test/file.dart',
        hasChanges: true,
        appliedRules: ['rule1', 'rule2'],
        changes: ['change1', 'change2'],
      );

      expect(result.filePath, equals('/test/file.dart'));
      expect(result.hasChanges, isTrue);
      expect(result.appliedRules, equals(['rule1', 'rule2']));
      expect(result.changes, equals(['change1', 'change2']));
      expect(result.error, isNull);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('creates instance with error', () {
      const result = FixResult(
        filePath: '/test/file.dart',
        hasChanges: false,
        appliedRules: [],
        changes: [],
        error: 'Some error occurred',
      );

      expect(result.filePath, equals('/test/file.dart'));
      expect(result.hasChanges, isFalse);
      expect(result.appliedRules, isEmpty);
      expect(result.changes, isEmpty);
      expect(result.error, equals('Some error occurred'));
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
    });

    group('factory constructors', () {
      test('creates success result', () {
        final result = FixResult.success(
          filePath: '/test/file.dart',
          appliedRules: const ['rule1'],
          changes: const ['Applied rule1'],
        );

        expect(result.filePath, equals('/test/file.dart'));
        expect(result.hasChanges, isTrue);
        expect(result.appliedRules, equals(['rule1']));
        expect(result.changes, equals(['Applied rule1']));
        expect(result.error, isNull);
        expect(result.isSuccess, isTrue);
      });

      test('creates success result with no changes', () {
        final result = FixResult.success(
          filePath: '/test/file.dart',
          appliedRules: const [],
          changes: const [],
        );

        expect(result.hasChanges, isFalse);
        expect(result.isSuccess, isTrue);
      });

      test('creates failure result', () {
        final result = FixResult.failure(
          filePath: '/test/file.dart',
          error: 'File not found',
        );

        expect(result.filePath, equals('/test/file.dart'));
        expect(result.hasChanges, isFalse);
        expect(result.appliedRules, isEmpty);
        expect(result.changes, isEmpty);
        expect(result.error, equals('File not found'));
        expect(result.isFailure, isTrue);
      });
    });

    group('toJson', () {
      test('serializes success result', () {
        const result = FixResult(
          filePath: '/test/file.dart',
          hasChanges: true,
          appliedRules: ['rule1', 'rule2'],
          changes: ['change1', 'change2'],
        );

        final json = result.toJson();

        expect(json['filePath'], equals('/test/file.dart'));
        expect(json['hasChanges'], isTrue);
        expect(json['appliedRules'], equals(['rule1', 'rule2']));
        expect(json['changes'], equals(['change1', 'change2']));
        expect(json.containsKey('error'), isFalse);
      });

      test('serializes failure result', () {
        const result = FixResult(
          filePath: '/test/file.dart',
          hasChanges: false,
          appliedRules: [],
          changes: [],
          error: 'Some error',
        );

        final json = result.toJson();

        expect(json['filePath'], equals('/test/file.dart'));
        expect(json['hasChanges'], isFalse);
        expect(json['appliedRules'], isEmpty);
        expect(json['changes'], isEmpty);
        expect(json['error'], equals('Some error'));
      });
    });

    group('equality', () {
      test('equal instances', () {
        const result1 = FixResult(
          filePath: '/test/file.dart',
          hasChanges: true,
          appliedRules: ['rule1'],
          changes: ['change1'],
        );

        const result2 = FixResult(
          filePath: '/test/file.dart',
          hasChanges: true,
          appliedRules: ['rule1'],
          changes: ['change1'],
        );

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('not equal when filePath differs', () {
        const result1 = FixResult(
          filePath: '/test/file1.dart',
          hasChanges: true,
          appliedRules: [],
          changes: [],
        );

        const result2 = FixResult(
          filePath: '/test/file2.dart',
          hasChanges: true,
          appliedRules: [],
          changes: [],
        );

        expect(result1, isNot(equals(result2)));
      });

      test('not equal when error differs', () {
        const result1 = FixResult(
          filePath: '/test/file.dart',
          hasChanges: false,
          appliedRules: [],
          changes: [],
          error: 'Error 1',
        );

        const result2 = FixResult(
          filePath: '/test/file.dart',
          hasChanges: false,
          appliedRules: [],
          changes: [],
          error: 'Error 2',
        );

        expect(result1, isNot(equals(result2)));
      });
    });
  });
}
