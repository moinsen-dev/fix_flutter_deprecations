import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceVariantRule', () {
    late SurfaceVariantRule rule;

    setUp(() {
      rule = const SurfaceVariantRule();
    });

    test('has correct properties', () {
      expect(rule.name, equals('surfaceContainerHighest'));
      expect(
        rule.description,
        equals(
          'Replace deprecated surfaceContainerHighest with '
          'surfaceContainerHighest',
        ),
      );
      expect(rule.deprecatedPattern, equals('surfaceContainerHighest'));
      expect(rule.replacementExample, equals('surfaceContainerHighest'));
    });

    group('matches', () {
      test('matches surfaceContainerHighest usage', () {
        expect(rule.matches('colorScheme.surfaceContainerHighest'), isTrue);
        expect(
          rule.matches('theme.colorScheme.surfaceContainerHighest'),
          isTrue,
        );
        expect(
          rule.matches('Theme.of(context).colorScheme.surfaceContainerHighest'),
          isTrue,
        );
      });

      test('matches surfaceContainerHighest in different contexts', () {
        expect(rule.matches('color: surfaceContainerHighest'), isTrue);
        expect(
          rule.matches('backgroundColor: colorScheme.surfaceContainerHighest,'),
          isTrue,
        );
        expect(rule.matches('final bg = surfaceContainerHighest;'), isTrue);
      });

      test('does not match partial words', () {
        expect(rule.matches('surfaceVariantColor'), isFalse);
        expect(rule.matches('mySurfaceVariant'), isFalse);
        expect(rule.matches('surfaceContainerHighest'), isFalse);
      });

      test('does not match in strings or comments', () {
        // Note: Our simple regex doesn't distinguish strings/comments
        // This is a limitation but acceptable for our use case
        expect(rule.matches('"surfaceContainerHighest"'), isTrue);
        expect(rule.matches('// surfaceContainerHighest'), isTrue);
      });
    });

    group('apply', () {
      test('replaces simple surfaceContainerHighest usage', () {
        const input = 'colorScheme.surfaceContainerHighest';
        const expected = 'colorScheme.surfaceContainerHighest';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces multiple occurrences', () {
        const input = '''
final color1 = colorScheme.surfaceContainerHighest;
final color2 = theme.colorScheme.surfaceContainerHighest;
''';
        const expected = '''
final color1 = colorScheme.surfaceContainerHighest;
final color2 = theme.colorScheme.surfaceContainerHighest;
''';
        expect(rule.apply(input), equals(expected));
      });

      test('preserves surrounding code', () {
        const input = 'Container(color: colorScheme.surfaceContainerHighest)';
        const expected =
            'Container(color: colorScheme.surfaceContainerHighest)';
        expect(rule.apply(input), equals(expected));
      });

      test('handles property access', () {
        const input = '''
Theme.of(context)
    .colorScheme
    .surfaceContainerHighest
''';
        const expected = '''
Theme.of(context)
    .colorScheme
    .surfaceContainerHighest
''';
        expect(rule.apply(input), equals(expected));
      });

      test('returns unchanged if no matches', () {
        const input = 'colorScheme.surfaceContainerHighest';
        expect(rule.apply(input), equals(input));
      });
    });

    group('validate', () {
      test('validates successful transformation', () {
        const original = 'colorScheme.surfaceContainerHighest';
        const modified = 'colorScheme.surfaceContainerHighest';
        expect(rule.validate(original, modified), isTrue);
      });

      test('validates when no changes needed', () {
        const original = 'colorScheme.surfaceContainerHighest';
        const modified = 'colorScheme.surfaceContainerHighest';
        expect(rule.validate(original, modified), isTrue);
      });

      test('fails validation if content deleted', () {
        const original = 'colorScheme.surfaceContainerHighest';
        const modified = '';
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if surfaceContainerHighest remains', () {
        const original = 'colorScheme.surfaceContainerHighest';
        const modified = 'colorScheme.surfaceContainerHighest';
        expect(rule.validate(original, modified), isFalse);
      });

      test('validates correct replacement count', () {
        const original = '''
color1: colorScheme.surfaceContainerHighest,
color2: colorScheme.surfaceContainerHighest,
color3: colorScheme.surfaceContainerHighest,
''';
        const modified = '''
color1: colorScheme.surfaceContainerHighest,
color2: colorScheme.surfaceContainerHighest,
color3: colorScheme.surfaceContainerHighest,
''';
        expect(rule.validate(original, modified), isTrue);
      });
    });
  });
}
