import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

// Single-line fixtures (with \n escapes) keep helper-named top-level
// declarations off real source lines so the rule does not self-apply.
void main() {
  group('UnreachableFromMainRule', () {
    const rule = UnreachableFromMainRule();

    test('matches helper-named top-level fn in a file with main', () {
      const input = 'void main() {}\n\nvoid removeMockEvent(String id) {}\n';
      expect(rule.matches(input), isTrue);
    });

    test('does not match when no main is present', () {
      const input = 'void removeMockEvent(String id) {}';
      expect(rule.matches(input), isFalse);
    });

    test('does not match when helper word is missing', () {
      const input = 'void main() {}\n\nvoid renderTile(String id) {}\n';
      expect(rule.matches(input), isFalse);
    });

    test('does not double-tag already-ignored functions', () {
      const input =
          'void main() {}\n\n'
          '// ignore: unreachable_from_main\n'
          'void removeMockEvent(String id) {}\n';
      expect(rule.matches(input), isFalse);
    });

    test('inserts ignore comment above qualifying declaration', () {
      const input = 'void main() {}\n\nvoid removeMockEvent(String id) {}\n';
      final out = rule.apply(input);
      expect(out, contains('// ignore: unreachable_from_main'));
      expect(
        out.indexOf('// ignore: unreachable_from_main'),
        lessThan(out.indexOf('void removeMockEvent')),
      );
    });
  });
}
