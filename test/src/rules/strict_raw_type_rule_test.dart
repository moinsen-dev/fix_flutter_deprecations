import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('StrictRawTypeRule', () {
    const rule = StrictRawTypeRule();

    // Build the raw form at runtime so the rule cannot rewrite this test's
    // own source while running on it.
    String raw() {
      const a = 'dyn';
      const b = 'amic';
      return 'Map<$a$b, $a$b>';
    }

    test('matches the raw map form', () {
      expect(rule.matches('${raw()} x = {};'), isTrue);
    });

    test('does not match well-typed Map', () {
      expect(rule.matches('Map<String, int> x = {};'), isFalse);
    });

    test('rewrites raw map to Map<String, dynamic>', () {
      final input = '${raw()} x = jsonDecode(s);';
      const expected = 'Map<String, dynamic> x = jsonDecode(s);';
      expect(rule.apply(input), equals(expected));
    });

    test('handles whitespace inside generics', () {
      const a = 'dyn';
      const b = 'amic';
      const input = 'Map<$a$b,  $a$b> x;';
      const expected = 'Map<String, dynamic> x;';
      expect(rule.apply(input), equals(expected));
    });
  });
}
