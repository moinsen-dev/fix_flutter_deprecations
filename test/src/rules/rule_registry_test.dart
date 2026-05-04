import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('RuleRegistry', () {
    test('allRules contains all expected rules', () {
      expect(RuleRegistry.allRules.length, equals(15));

      final ruleTypes = RuleRegistry.allRules.map((r) => r.runtimeType).toSet();
      expect(ruleTypes, contains(WithOpacityRule));
      expect(ruleTypes, contains(SurfaceVariantRule));
      expect(ruleTypes, contains(WillPopScopeRule));
      expect(ruleTypes, contains(MultipleUnderscoresRule));
      expect(ruleTypes, contains(BuildContextAsyncRule));
    });

    test('availableRuleNames returns all rule names', () {
      final names = RuleRegistry.availableRuleNames;

      expect(names.length, equals(15));
      expect(names, contains('withOpacity'));
      expect(names, contains('surfaceContainerHighest'));
      expect(names, contains('willPopScope'));
      expect(names, contains('multipleUnderscores'));
      expect(names, contains('buildContextAsync'));
    });

    group('getRules', () {
      test('returns all rules when ruleNames is null', () {
        final rules = RuleRegistry.getRules(null);
        expect(rules.length, equals(15));
      });

      test('returns all rules when ruleNames is empty', () {
        final rules = RuleRegistry.getRules([]);
        expect(rules.length, equals(15));
      });

      test('returns specific rules by name', () {
        final rules = RuleRegistry.getRules(['withOpacity']);

        expect(rules.length, equals(1));
        expect(rules.first, isA<WithOpacityRule>());
      });

      test('returns multiple specific rules', () {
        final rules = RuleRegistry.getRules([
          'withOpacity',
          'surfaceContainerHighest',
        ]);

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
                .having(
                  (e) => e.message,
                  'message',
                  contains('surfaceContainerHighest'),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains('onSurface'),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains('willPopScope'),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains('multipleUnderscores'),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains('buildContextAsync'),
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
          RuleRegistry.getRule('surfaceContainerHighest'),
          isA<SurfaceVariantRule>(),
        );
        expect(
          RuleRegistry.getRule('onSurface'),
          isA<OnSurfaceVariantRule>(),
        );
        expect(
          RuleRegistry.getRule('willPopScope'),
          isA<WillPopScopeRule>(),
        );
        expect(
          RuleRegistry.getRule('multipleUnderscores'),
          isA<MultipleUnderscoresRule>(),
        );
        expect(
          RuleRegistry.getRule('buildContextAsync'),
          isA<BuildContextAsyncRule>(),
        );
      });
    });

    group('validateRuleNames', () {
      test('returns true for valid rule names', () {
        expect(
          RuleRegistry.validateRuleNames([
            'withOpacity',
            'surfaceContainerHighest',
          ]),
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
          ['withOpacity', 'surfaceContainerHighest'],
        );
        expect(invalid, isEmpty);
      });

      test('returns invalid rule names', () {
        final invalid = RuleRegistry.getInvalidRuleNames(
          ['withOpacity', 'badRule', 'surfaceContainerHighest', 'anotherBad'],
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
