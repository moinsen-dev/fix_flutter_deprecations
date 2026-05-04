import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('RemovedLintRule', () {
    const rule = RemovedLintRule();

    test('targets analysis_options.yaml only', () {
      expect(rule.appliesToExtensions, equals({'analysis_options.yaml'}));
    });

    test('matches a removed lint name in dash list', () {
      const input = '''
linter:
  rules:
    - package_api_docs
    - prefer_const_constructors
''';
      expect(rule.matches(input), isTrue);
    });

    test('does not match when no removed lints are present', () {
      const input = '''
linter:
  rules:
    - prefer_const_constructors
''';
      expect(rule.matches(input), isFalse);
    });

    test('removes the offending line', () {
      const input = '''
linter:
  rules:
    - package_api_docs
    - prefer_const_constructors
''';
      final out = rule.apply(input);
      expect(out, isNot(contains('package_api_docs')));
      expect(out, contains('prefer_const_constructors'));
    });

    test('removes lint with explicit boolean form', () {
      const input = '''
linter:
  rules:
    package_api_docs: false
    prefer_final_locals: true
''';
      final out = rule.apply(input);
      expect(out, isNot(contains('package_api_docs')));
      expect(out, contains('prefer_final_locals'));
    });
  });
}
