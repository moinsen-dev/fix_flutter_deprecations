// fix_flutter_deprecations: ignore_file

import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('WithOpacityRule', () {
    late WithOpacityRule rule;

    setUp(() {
      rule = const WithOpacityRule();
    });

    test('has correct properties', () {
      expect(rule.name, equals('withOpacity'));
      expect(
        rule.description,
        equals('Replace deprecated .withOpacity() with .withValues(alpha:)'),
      );
      expect(rule.deprecatedPattern, equals(r'\.withOpacity\('));
      expect(rule.replacementExample, equals('.withValues(alpha: value)'));
    });

    group('matches', () {
      test('matches simple withOpacity calls', () {
        expect(rule.matches('Colors.blue.withOpacity(0.5)'), isTrue);
        expect(rule.matches('color.withOpacity(0.8)'), isTrue);
        expect(
          rule.matches('Theme.of(context).primaryColor.withOpacity(0.3)'),
          isTrue,
        );
      });

      test('matches withOpacity with spaces', () {
        expect(rule.matches('color.withOpacity( 0.5 )'), isTrue);
        expect(rule.matches('color.withOpacity(\n  0.5\n)'), isTrue);
        expect(rule.matches('color .withOpacity (0.5)'), isTrue);
      });

      test('does not match withValues', () {
        expect(rule.matches('color.withValues(alpha: 0.5)'), isFalse);
        expect(rule.matches('withOpacity'), isFalse);
        expect(rule.matches('.withOpacity'), isFalse);
      });
    });

    group('apply', () {
      test('replaces simple withOpacity calls', () {
        const input = 'Colors.blue.withOpacity(0.5)';
        const expected = 'Colors.blue.withValues(alpha: 0.5)';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces multiple withOpacity calls', () {
        const input = '''
final color1 = Colors.red.withOpacity(0.3);
final color2 = Colors.green.withOpacity(0.7);
''';
        const expected = '''
final color1 = Colors.red.withValues(alpha: 0.3);
final color2 = Colors.green.withValues(alpha: 0.7);
''';
        expect(rule.apply(input), equals(expected));
      });

      test('preserves spacing in arguments', () {
        const input = 'color.withOpacity( 0.5 )';
        const expected = 'color.withValues(alpha: 0.5)';
        expect(rule.apply(input), equals(expected));
      });

      test('handles complex expressions', () {
        const input = 'color.withOpacity(opacity * 0.5)';
        const expected = 'color.withValues(alpha: opacity * 0.5)';
        expect(rule.apply(input), equals(expected));
      });

      test('handles nested parentheses', () {
        const input = 'color.withOpacity(getOpacity(0.5))';
        const expected = 'color.withValues(alpha: getOpacity(0.5))';
        expect(rule.apply(input), equals(expected));
      });

      test('handles method chains', () {
        const input = '''
Theme.of(context)
    .primaryColor
    .withOpacity(0.5)
    .toString();
''';
        const expected = '''
Theme.of(context)
    .primaryColor
    .withValues(alpha: 0.5)
    .toString();
''';
        expect(rule.apply(input), equals(expected));
      });

      test('returns unchanged if no matches', () {
        const input = 'color.withValues(alpha: 0.5)';
        expect(rule.apply(input), equals(input));
      });
    });

    group('validate', () {
      test('validates successful transformation', () {
        const original = 'Colors.blue.withOpacity(0.5)';
        const modified = 'Colors.blue.withValues(alpha: 0.5)';
        expect(rule.validate(original, modified), isTrue);
      });

      test('validates when no changes needed', () {
        const original = 'Colors.blue.withValues(alpha: 0.5)';
        const modified = 'Colors.blue.withValues(alpha: 0.5)';
        expect(rule.validate(original, modified), isTrue);
      });

      test('fails validation if content deleted', () {
        const original = 'Colors.blue.withOpacity(0.5)';
        const modified = '';
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if line count changes', () {
        const original = 'Colors.blue.withOpacity(0.5)';
        const modified = 'Colors.blue\n.withValues(alpha: 0.5)';
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if withOpacity remains', () {
        const original = 'Colors.blue.withOpacity(0.5)';
        const modified = 'Colors.blue.withOpacity(0.5)';
        expect(rule.validate(original, modified), isFalse);
      });
    });
  });
}
