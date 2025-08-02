import 'package:fix_flutter_deprecations/src/models/models.dart';
import 'package:test/test.dart';

void main() {
  group('FixOptions', () {
    test('creates instance with required parameters', () {
      const options = FixOptions(targetPath: '/test/path');

      expect(options.targetPath, equals('/test/path'));
      expect(options.dryRun, isFalse);
      expect(options.backup, isTrue);
      expect(options.verbose, isFalse);
      expect(options.rules, isNull);
    });

    test('creates instance with all parameters', () {
      const options = FixOptions(
        targetPath: '/test/path',
        dryRun: true,
        backup: false,
        verbose: true,
        rules: ['rule1', 'rule2'],
      );

      expect(options.targetPath, equals('/test/path'));
      expect(options.dryRun, isTrue);
      expect(options.backup, isFalse);
      expect(options.verbose, isTrue);
      expect(options.rules, equals(['rule1', 'rule2']));
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const original = FixOptions(targetPath: '/test/path');
        final copy = original.copyWith();

        expect(copy.targetPath, equals(original.targetPath));
        expect(copy.dryRun, equals(original.dryRun));
        expect(copy.backup, equals(original.backup));
        expect(copy.verbose, equals(original.verbose));
        expect(copy.rules, equals(original.rules));
      });

      test('copies with targetPath change', () {
        const original = FixOptions(targetPath: '/test/path');
        final copy = original.copyWith(targetPath: '/new/path');

        expect(copy.targetPath, equals('/new/path'));
        expect(copy.dryRun, equals(original.dryRun));
      });

      test('copies with all changes', () {
        const original = FixOptions(
          targetPath: '/test/path',
        );

        final copy = original.copyWith(
          targetPath: '/new/path',
          dryRun: true,
          backup: false,
          verbose: true,
          rules: ['rule1'],
        );

        expect(copy.targetPath, equals('/new/path'));
        expect(copy.dryRun, isTrue);
        expect(copy.backup, isFalse);
        expect(copy.verbose, isTrue);
        expect(copy.rules, equals(['rule1']));
      });
    });

    group('equality', () {
      test('equal instances', () {
        const options1 = FixOptions(
          targetPath: '/test/path',
          dryRun: true,
          backup: false,
          verbose: true,
          rules: ['rule1', 'rule2'],
        );

        const options2 = FixOptions(
          targetPath: '/test/path',
          dryRun: true,
          backup: false,
          verbose: true,
          rules: ['rule1', 'rule2'],
        );

        expect(options1, equals(options2));
        expect(options1.hashCode, equals(options2.hashCode));
      });

      test('not equal when targetPath differs', () {
        const options1 = FixOptions(targetPath: '/path1');
        const options2 = FixOptions(targetPath: '/path2');

        expect(options1, isNot(equals(options2)));
      });

      test('not equal when dryRun differs', () {
        const options1 = FixOptions(targetPath: '/path', dryRun: true);
        const options2 = FixOptions(targetPath: '/path');

        expect(options1, isNot(equals(options2)));
      });

      test('not equal when rules differ', () {
        const options1 = FixOptions(
          targetPath: '/path',
          rules: ['rule1'],
        );
        const options2 = FixOptions(
          targetPath: '/path',
          rules: ['rule2'],
        );

        expect(options1, isNot(equals(options2)));
      });
    });
  });
}
