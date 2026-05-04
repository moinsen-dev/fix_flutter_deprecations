import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

// Single-line fixtures with \n escapes so the rule does not self-apply
// when run against this test file's source.
void main() {
  group('CascadeInvocationsRule', () {
    const rule = CascadeInvocationsRule();

    test('matches two consecutive calls on same receiver', () {
      const input = 'void f() {\n  buf.add(1);\n  buf.add(2);\n}';
      expect(rule.matches(input), isTrue);
    });

    test('does not match when receivers differ', () {
      const input = 'void f() {\n  a.add(1);\n  b.add(2);\n}';
      expect(rule.matches(input), isFalse);
    });

    test('does not match when assignment is involved', () {
      const input = 'void f() {\n  buf = buf.add(1);\n  buf.add(2);\n}';
      expect(rule.matches(input), isFalse);
    });

    test('rewrites a 3-line run into a cascade', () {
      const input =
          'void f() {\n  buf.add(1);\n  buf.add(2);\n  buf.add(3);\n}';
      const expected =
          'void f() {\n  buf\n    ..add(1)\n    ..add(2)\n    ..add(3);\n}';
      expect(rule.apply(input), equals(expected));
    });

    test('leaves single calls alone', () {
      const input = 'void f() { buf.add(1); }';
      expect(rule.apply(input), equals(input));
    });

    test('does not modify when matches() is false', () {
      const input = 'void f() {}';
      expect(rule.apply(input), equals(input));
    });

    test('does not cascade static calls on a class (uppercase receiver)', () {
      const input = 'void f() {\n  Box.register(A);\n  Box.register(B);\n}';
      expect(rule.matches(input), isFalse);
      expect(rule.apply(input), equals(input));
    });
  });
}
