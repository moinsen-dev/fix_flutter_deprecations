import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('OnSurfaceVariantRule', () {
    late OnSurfaceVariantRule rule;

    setUp(() {
      rule = const OnSurfaceVariantRule();
    });

    test('has correct properties', () {
      expect(rule.name, equals('onSurface'));
      expect(
        rule.description,
        equals('Replace deprecated onSurface with onSurface'),
      );
      expect(rule.deprecatedPattern, equals('onSurface'));
      expect(rule.replacementExample, equals('onSurface'));
    });

    group('matches', () {
      test('matches onSurface usage', () {
        expect(rule.matches('colorScheme.onSurface'), isTrue);
        expect(rule.matches('theme.colorScheme.onSurface'), isTrue);
        expect(
          rule.matches('Theme.of(context).colorScheme.onSurface'),
          isTrue,
        );
      });

      test('matches onSurface in different contexts', () {
        expect(rule.matches('color: onSurface'), isTrue);
        expect(
          rule.matches('foregroundColor: colorScheme.onSurface,'),
          isTrue,
        );
        expect(rule.matches('final textColor = onSurface;'), isTrue);
      });

      test('does not match partial words', () {
        expect(rule.matches('onSurfaceVariantColor'), isFalse);
        expect(rule.matches('myOnSurfaceVariant'), isFalse);
        expect(rule.matches('onSurface'), isFalse);
      });
    });

    group('apply', () {
      test('replaces simple onSurface usage', () {
        const input = 'colorScheme.onSurface';
        const expected = 'colorScheme.onSurface';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces multiple occurrences', () {
        const input = '''
final color1 = colorScheme.onSurface;
final color2 = theme.colorScheme.onSurface;
''';
        const expected = '''
final color1 = colorScheme.onSurface;
final color2 = theme.colorScheme.onSurface;
''';
        expect(rule.apply(input), equals(expected));
      });

      test('preserves surrounding code', () {
        const input = 'TextStyle(color: colorScheme.onSurface)';
        const expected = 'TextStyle(color: colorScheme.onSurface)';
        expect(rule.apply(input), equals(expected));
      });

      test('handles property access', () {
        const input = '''
Theme.of(context)
    .colorScheme
    .onSurface
''';
        const expected = '''
Theme.of(context)
    .colorScheme
    .onSurface
''';
        expect(rule.apply(input), equals(expected));
      });

      test('returns unchanged if no matches', () {
        const input = 'colorScheme.onSurface';
        expect(rule.apply(input), equals(input));
      });
    });

    group('validate', () {
      test('validates successful transformation', () {
        const original = 'colorScheme.onSurface';
        const modified = 'colorScheme.onSurface';
        expect(rule.validate(original, modified), isTrue);
      });

      test('validates when no changes needed', () {
        const original = 'colorScheme.onSurface';
        const modified = 'colorScheme.onSurface';
        expect(rule.validate(original, modified), isTrue);
      });

      test('fails validation if content deleted', () {
        const original = 'colorScheme.onSurface';
        const modified = '';
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if onSurface remains', () {
        const original = 'colorScheme.onSurface';
        const modified = 'colorScheme.onSurface';
        expect(rule.validate(original, modified), isFalse);
      });

      test('validates when mixed onSurface and onSurface exist', () {
        const original = '''
color1: colorScheme.onSurface,
color2: colorScheme.onSurface,
''';
        const modified = '''
color1: colorScheme.onSurface,
color2: colorScheme.onSurface,
''';
        expect(rule.validate(original, modified), isTrue);
      });
    });
  });
}
