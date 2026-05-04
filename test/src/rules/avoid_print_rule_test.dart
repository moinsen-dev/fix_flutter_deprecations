import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('AvoidPrintRule', () {
    const rule = AvoidPrintRule();

    test('matches a bare print call', () {
      expect(rule.matches('void main() { print(42); }'), isTrue);
    });

    test('does not match when ignore is already on the line above', () {
      const input = '// ignore: avoid_print\nprint(42);';
      expect(rule.matches(input), isFalse);
    });

    test('does not match unrelated method named print', () {
      expect(rule.matches('foo.print();'), isFalse);
    });

    test('does not match print mentioned inside a string literal', () {
      expect(rule.matches('var s = "look: print(42)";'), isFalse);
    });

    test('inserts a documented ignore above the print', () {
      const input = 'void main() {\n  print(42);\n}';
      final out = rule.apply(input);
      expect(out, contains('// ignore: avoid_print'));
      expect(out, contains('Silenced by fix_deprecations'));
      expect(
        out.indexOf('// ignore: avoid_print'),
        lessThan(out.indexOf('print(42);')),
      );
    });

    test('handles multiple prints, each gets its own ignore', () {
      const input = 'void main() {\n  print(1);\n  print(2);\n}';
      final out = rule.apply(input);
      expect(out.split('// ignore: avoid_print').length - 1, equals(2));
    });

    test('skips prints in line comments', () {
      const input = '// print(42)';
      expect(rule.matches(input), isFalse);
    });

    test('skips files with file-level ignore_for_file: avoid_print', () {
      const input =
          '// ignore_for_file: avoid_print\n\n'
          'void main() { print(42); }';
      expect(rule.matches(input), isFalse);
    });

    test('skips files with mixed ignore_for_file list', () {
      const input =
          '// ignore_for_file: avoid_print, prefer_const\n\n'
          'void main() { print(42); }';
      expect(rule.matches(input), isFalse);
    });
  });
}
