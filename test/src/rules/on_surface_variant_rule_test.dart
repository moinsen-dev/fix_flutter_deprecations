import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('OnSurfaceVariantRule', () {
    late OnSurfaceVariantRule rule;

    setUp(() {
      rule = const OnSurfaceVariantRule();
    });

    test('has correct properties', () {
      expect(rule.name, equals('onSurfaceVariant'));
      expect(
        rule.description,
        equals('Replace deprecated onSurfaceVariant with onSurface'),
      );
      expect(rule.deprecatedPattern, equals('onSurfaceVariant'));
      expect(rule.replacementExample, equals('onSurface'));
    });

    group('matches', () {
      test('matches onSurfaceVariant usage', () {
        expect(rule.matches('colorScheme.onSurfaceVariant'), isTrue);
        expect(rule.matches('theme.colorScheme.onSurfaceVariant'), isTrue);
        expect(
          rule.matches('Theme.of(context).colorScheme.onSurfaceVariant'),
          isTrue,
        );
      });

      test('matches onSurfaceVariant in different contexts', () {
        expect(rule.matches('color: onSurfaceVariant'), isTrue);
        expect(
          rule.matches('foregroundColor: colorScheme.onSurfaceVariant,'),
          isTrue,
        );
        expect(rule.matches('final textColor = onSurfaceVariant;'), isTrue);
      });

      test('does not match partial words', () {
        expect(rule.matches('onSurfaceVariantColor'), isFalse);
        expect(rule.matches('myOnSurfaceVariant'), isFalse);
        expect(rule.matches('onSurface'), isFalse);
      });
    });

    group('apply', () {
      test('replaces simple onSurfaceVariant usage', () {
        const input = 'colorScheme.onSurfaceVariant';
        const expected = 'colorScheme.onSurface';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces multiple occurrences', () {
        const input = '''
final color1 = colorScheme.onSurfaceVariant;
final color2 = theme.colorScheme.onSurfaceVariant;
''';
        const expected = '''
final color1 = colorScheme.onSurface;
final color2 = theme.colorScheme.onSurface;
''';
        expect(rule.apply(input), equals(expected));
      });

      test('preserves surrounding code', () {
        const input = 'TextStyle(color: colorScheme.onSurfaceVariant)';
        const expected = 'TextStyle(color: colorScheme.onSurface)';
        expect(rule.apply(input), equals(expected));
      });

      test('handles property access', () {
        const input = '''
Theme.of(context)
    .colorScheme
    .onSurfaceVariant
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
        const original = 'colorScheme.onSurfaceVariant';
        const modified = 'colorScheme.onSurface';
        expect(rule.validate(original, modified), isTrue);
      });

      test('validates when no changes needed', () {
        const original = 'colorScheme.onSurface';
        const modified = 'colorScheme.onSurface';
        expect(rule.validate(original, modified), isTrue);
      });

      test('fails validation if content deleted', () {
        const original = 'colorScheme.onSurfaceVariant';
        const modified = '';
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if onSurfaceVariant remains', () {
        const original = 'colorScheme.onSurfaceVariant';
        const modified = 'colorScheme.onSurfaceVariant';
        expect(rule.validate(original, modified), isFalse);
      });

      test('validates when onSurface already exists', () {
        const original = '''
color1: colorScheme.onSurfaceVariant,
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
