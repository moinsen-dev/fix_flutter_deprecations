// fix_flutter_deprecations: ignore_file
import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('StrictRawTypeRule', () {
    const rule = StrictRawTypeRule();

    // Build the raw forms at runtime so the rule cannot rewrite this
    // test's own source while running on it.
    String rawMap() {
      const a = 'dyn';
      const b = 'amic';
      return 'Map<$a$b, $a$b>';
    }

    String bareMap() => 'Ma${'p'}';
    String bareList() => 'Li${'st'}';

    test('matches the raw map form', () {
      expect(rule.matches('${rawMap()} x = {};'), isTrue);
    });

    test('does not match well-typed Map', () {
      expect(rule.matches('Map<String, int> x = {};'), isFalse);
    });

    test('rewrites raw map to Map<String, dynamic>', () {
      final input = '${rawMap()} x = jsonDecode(s);';
      const expected = 'Map<String, dynamic> x = jsonDecode(s);';
      expect(rule.apply(input), equals(expected));
    });

    test('matches bare Map as a generic argument', () {
      final input = 'expect(x, isA<${bareMap()}>());';
      expect(rule.matches(input), isTrue);
    });

    test('rewrites bare Map argument to Map<String, dynamic>', () {
      final input = 'expect(x, isA<${bareMap()}>());';
      const expected = 'expect(x, isA<Map<String, dynamic>>());';
      expect(rule.apply(input), equals(expected));
    });

    test('rewrites bare List argument to List<dynamic>', () {
      final input = 'expect(x, isA<${bareList()}>());';
      const expected = 'expect(x, isA<List<dynamic>>());';
      expect(rule.apply(input), equals(expected));
    });

    test('does not touch parameterised Map/List', () {
      const input = 'expect(x, isA<Map<String, int>>());\n'
          'expect(y, isA<List<int>>());';
      expect(rule.matches(input), isFalse);
      expect(rule.apply(input), equals(input));
    });
  });
}
