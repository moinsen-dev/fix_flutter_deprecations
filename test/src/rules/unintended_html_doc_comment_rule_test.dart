import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('UnintendedHtmlDocCommentRule', () {
    const rule = UnintendedHtmlDocCommentRule();

    test('matches <Type> in a doc comment', () {
      expect(rule.matches('/// returns a <Future<String>>'), isTrue);
    });

    test('does not match when wrapped in backticks', () {
      expect(rule.matches('/// returns a `<Future<String>>`'), isFalse);
    });

    test('does not match in regular code', () {
      expect(rule.matches('Future<String> foo() => "";'), isFalse);
    });

    test('ignores allowed HTML tags', () {
      expect(rule.matches('/// line<br>break'), isFalse);
      expect(rule.matches('/// <p>paragraph</p>'), isFalse);
    });

    test('wraps a single <Type>', () {
      const input = '/// uses <Future<int>> internally';
      const expected = '/// uses `<Future<int>>` internally';
      expect(rule.apply(input), equals(expected));
    });

    test('only touches /// lines', () {
      const input = '''
class Foo<T> {
  /// returns `<List<T>>`
  List<T> bar() => [];
}''';
      final out = rule.apply(input);
      expect(out, contains('/// returns `<List<T>>`'));
      expect(out, contains('class Foo<T>'));
      expect(out, contains('List<T> bar()'));
    });
  });
}
