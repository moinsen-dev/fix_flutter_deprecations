import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('RuleRegistry', () {
    test('allRules contains all expected rules', () {
      expect(RuleRegistry.allRules.length, equals(3));

      final ruleTypes = RuleRegistry.allRules.map((r) => r.runtimeType).toSet();
      expect(ruleTypes, contains(WithOpacityRule));
      expect(ruleTypes, contains(SurfaceVariantRule));
      expect(ruleTypes, contains(OnSurfaceVariantRule));
    });

    test('availableRuleNames returns all rule names', () {
      final names = RuleRegistry.availableRuleNames;

      expect(names.length, equals(3));
      expect(names, contains('withOpacity'));
      expect(names, contains('surfaceVariant'));
      expect(names, contains('onSurfaceVariant'));
    });

    group('getRules', () {
      test('returns all rules when ruleNames is null', () {
        final rules = RuleRegistry.getRules(null);
        expect(rules.length, equals(3));
      });

      test('returns all rules when ruleNames is empty', () {
        final rules = RuleRegistry.getRules([]);
        expect(rules.length, equals(3));
      });

      test('returns specific rules by name', () {
        final rules = RuleRegistry.getRules(['withOpacity']);

        expect(rules.length, equals(1));
        expect(rules.first, isA<WithOpacityRule>());
      });

      test('returns multiple specific rules', () {
        final rules = RuleRegistry.getRules(['withOpacity', 'surfaceVariant']);

        expect(rules.length, equals(2));
        expect(rules.any((r) => r is WithOpacityRule), isTrue);
        expect(rules.any((r) => r is SurfaceVariantRule), isTrue);
      });

      test('throws ArgumentError for unknown rule', () {
        expect(
          () => RuleRegistry.getRules(['unknownRule']),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Unknown rule'),
            ),
          ),
        );
      });

      test('throws ArgumentError with available rules in message', () {
        expect(
          () => RuleRegistry.getRules(['badRule']),
          throwsA(
            isA<ArgumentError>()
                .having((e) => e.message, 'message', contains('withOpacity'))
                .having((e) => e.message, 'message', contains('surfaceVariant'))
                .having(
                  (e) => e.message,
                  'message',
                  contains('onSurfaceVariant'),
                ),
          ),
        );
      });
    });

    group('getRule', () {
      test('returns rule by name', () {
        final rule = RuleRegistry.getRule('withOpacity');

        expect(rule, isNotNull);
        expect(rule, isA<WithOpacityRule>());
      });

      test('returns null for unknown rule', () {
        final rule = RuleRegistry.getRule('unknownRule');
        expect(rule, isNull);
      });

      test('returns correct rule for each name', () {
        expect(RuleRegistry.getRule('withOpacity'), isA<WithOpacityRule>());
        expect(
          RuleRegistry.getRule('surfaceVariant'),
          isA<SurfaceVariantRule>(),
        );
        expect(
          RuleRegistry.getRule('onSurfaceVariant'),
          isA<OnSurfaceVariantRule>(),
        );
      });
    });

    group('validateRuleNames', () {
      test('returns true for valid rule names', () {
        expect(
          RuleRegistry.validateRuleNames(['withOpacity', 'surfaceVariant']),
          isTrue,
        );
      });

      test('returns true for empty list', () {
        expect(RuleRegistry.validateRuleNames([]), isTrue);
      });

      test('returns false for invalid rule name', () {
        expect(
          RuleRegistry.validateRuleNames(['withOpacity', 'unknownRule']),
          isFalse,
        );
      });

      test('returns false for all invalid names', () {
        expect(
          RuleRegistry.validateRuleNames(['bad1', 'bad2']),
          isFalse,
        );
      });
    });

    group('getInvalidRuleNames', () {
      test('returns empty for valid rule names', () {
        final invalid = RuleRegistry.getInvalidRuleNames(
          ['withOpacity', 'surfaceVariant'],
        );
        expect(invalid, isEmpty);
      });

      test('returns invalid rule names', () {
        final invalid = RuleRegistry.getInvalidRuleNames(
          ['withOpacity', 'badRule', 'surfaceVariant', 'anotherBad'],
        );

        expect(invalid.length, equals(2));
        expect(invalid, contains('badRule'));
        expect(invalid, contains('anotherBad'));
      });

      test('returns all names when all invalid', () {
        final invalid = RuleRegistry.getInvalidRuleNames(['bad1', 'bad2']);

        expect(invalid.length, equals(2));
        expect(invalid, equals(['bad1', 'bad2']));
      });
    });
  });
}
