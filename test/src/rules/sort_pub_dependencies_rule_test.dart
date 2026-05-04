import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('SortPubDependenciesRule', () {
    const rule = SortPubDependenciesRule();

    test('targets pubspec.yaml only', () {
      expect(rule.appliesToExtensions, equals({'pubspec.yaml'}));
    });

    test('matches when dependencies are out of order', () {
      const input = '''
name: x
dependencies:
  zeta: ^1.0.0
  alpha: ^1.0.0
''';
      expect(rule.matches(input), isTrue);
    });

    test('does not match when sorted', () {
      const input = '''
name: x
dependencies:
  alpha: ^1.0.0
  zeta: ^1.0.0
''';
      expect(rule.matches(input), isFalse);
    });

    test('sorts a simple dependencies block', () {
      const input = '''
name: x
dependencies:
  zeta: ^1.0.0
  alpha: ^1.0.0
  middle: ^1.0.0
''';
      final out = rule.apply(input);
      final lines = out.split('\n');
      final depStart = lines.indexWhere((l) => l.trim() == 'dependencies:') + 1;
      expect(lines[depStart].trim(), startsWith('alpha'));
      expect(lines[depStart + 1].trim(), startsWith('middle'));
      expect(lines[depStart + 2].trim(), startsWith('zeta'));
    });

    test('preserves multi-line entries (e.g. flutter sdk)', () {
      const input = '''
dependencies:
  zeta: ^1.0.0
  flutter:
    sdk: flutter
  alpha: ^1.0.0
''';
      final out = rule.apply(input);
      // flutter block must keep its indented sdk line
      expect(
        out,
        contains('flutter:\n    sdk: flutter'),
      );
      // alpha must come first
      final alphaIdx = out.indexOf('alpha:');
      final flutterIdx = out.indexOf('flutter:');
      final zetaIdx = out.indexOf('zeta:');
      expect(alphaIdx, lessThan(flutterIdx));
      expect(flutterIdx, lessThan(zetaIdx));
    });

    test('sorts dev_dependencies block too', () {
      const input = '''
dev_dependencies:
  zeta: ^1.0.0
  alpha: ^1.0.0
''';
      final out = rule.apply(input);
      expect(out.indexOf('alpha'), lessThan(out.indexOf('zeta')));
    });
  });
}
