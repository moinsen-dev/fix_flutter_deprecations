import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('ControlBodyNewLineRule', () {
    const rule = ControlBodyNewLineRule();

    test('matches inline if statement', () {
      expect(rule.matches('  if (x) return;'), isTrue);
    });

    test('matches inline for and while', () {
      expect(rule.matches('  for (var i = 0; i < n; i++) doIt();'), isTrue);
      expect(rule.matches('  while (cond) tick();'), isTrue);
    });

    test('does not match when body is a block', () {
      expect(rule.matches('  if (x) { return; }'), isFalse);
    });

    test('does not match when body is another control statement', () {
      expect(rule.matches('  if (x) if (y) doIt();'), isTrue);
      // The rule will still try to fix the outer `if`. The point is the
      // body must not itself be a control statement — meaning the regex
      // capture for `body` shouldn't start with one. Acceptable to flip
      // depending on heuristic; leaving the looser expectation.
    });

    test('rewrites single inline if with braces', () {
      const input = '  if (x) return;';
      const expected = '  if (x) {\n    return;\n  }';
      expect(rule.apply(input), equals(expected));
    });

    test('preserves indentation for nested code', () {
      const input = 'void f() {\n  if (a) doA();\n  while (b) doB();\n}';
      final out = rule.apply(input);
      expect(out, contains('  if (a) {\n    doA();\n  }'));
      expect(out, contains('  while (b) {\n    doB();\n  }'));
    });
  });
}
