import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('FlutterStyleTodosRule', () {
    const rule = FlutterStyleTodosRule();

    // Build the trigger text at runtime so the rule does not self-apply
    // when scanning this test file's source. Source text never contains
    // `// TODO:` immediately preceded by whitespace.
    const slashes = '//';

    test('matches plain todo', () {
      expect(rule.matches('$slashes TODO: refactor this'), isTrue);
      expect(rule.matches('  $slashes TODO:something'), isTrue);
    });

    test('does not match already-tagged todo', () {
      expect(rule.matches('$slashes TODO(uli): later'), isFalse);
      expect(rule.matches('$slashes TODO(unassigned): yes'), isFalse);
    });

    test('does not match unrelated lines', () {
      expect(rule.matches('$slashes regular comment'), isFalse);
      expect(rule.matches('var todoList;'), isFalse);
    });

    test('rewrites a leading-line todo', () {
      const input = '$slashes TODO: do it later';
      const expected = '// TODO(unassigned): do it later';
      expect(rule.apply(input), equals(expected));
    });

    test('rewrites multiple todos in a file', () {
      const input =
          'class Foo {\n'
          '  $slashes TODO: a\n'
          '  void bar() {}\n'
          '  $slashes TODO: b\n'
          '}';
      final out = rule.apply(input);
      expect(out, contains('// TODO(unassigned): a'));
      expect(out, contains('// TODO(unassigned): b'));
    });

    test('appliesToExtensions defaults to .dart', () {
      expect(rule.appliesToExtensions, contains('.dart'));
    });
  });
}
