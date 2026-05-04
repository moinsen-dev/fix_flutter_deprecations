import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('DirectivesOrderingRule', () {
    const rule = DirectivesOrderingRule();

    test('matches unsorted package imports', () {
      const input = "import 'package:zeta/zeta.dart';\n"
          "import 'package:alpha/alpha.dart';\n";
      expect(rule.matches(input), isTrue);
    });

    test('does not match sorted imports', () {
      const input = "import 'package:alpha/alpha.dart';\n"
          "import 'package:zeta/zeta.dart';\n";
      expect(rule.matches(input), isFalse);
    });

    test('does not match a single import', () {
      const input = "import 'package:foo/foo.dart';\n";
      expect(rule.matches(input), isFalse);
    });

    test('sorts a small package block', () {
      const input = "import 'package:zeta/zeta.dart';\n"
          "import 'package:alpha/alpha.dart';\n";
      final out = rule.apply(input);
      final aIdx = out.indexOf('alpha');
      final zIdx = out.indexOf('zeta');
      expect(aIdx, lessThan(zIdx));
    });

    test('sorts within groups but keeps group order (dart, package, rel)',
        () {
      const input = "import 'package:zeta/zeta.dart';\n"
          "import 'dart:io';\n"
          "import '../foo.dart';\n"
          "import 'package:alpha/alpha.dart';\n"
          "import 'dart:async';\n"
          "import './bar.dart';\n";
      final out = rule.apply(input);
      // dart: comes first
      expect(out.indexOf('dart:async'), lessThan(out.indexOf('dart:io')));
      // package: middle
      expect(out.indexOf('dart:io'), lessThan(out.indexOf('package:alpha')));
      expect(
        out.indexOf('package:alpha'),
        lessThan(out.indexOf('package:zeta')),
      );
      // relative last, sorted alpha (`../` < `./` lexicographically)
      expect(
        out.indexOf('package:zeta'),
        lessThan(out.indexOf('../foo.dart')),
      );
      expect(
        out.indexOf('../foo.dart'),
        lessThan(out.indexOf('./bar.dart')),
      );
    });

    test('handles multi-line directives (with show)', () {
      const input = "import 'package:zeta/zeta.dart'\n"
          '    show A,\n'
          '    B;\n'
          "import 'package:alpha/alpha.dart';\n";
      final out = rule.apply(input);
      expect(out.indexOf('alpha'), lessThan(out.indexOf('zeta')));
      // multi-line `show` block must stay together
      expect(out, contains("'package:zeta/zeta.dart'\n    show A,\n    B;"));
    });

    test('leaves library/leading comments alone', () {
      const input = '/// docstring\n'
          'library;\n'
          '\n'
          "import 'package:zeta/zeta.dart';\n"
          "import 'package:alpha/alpha.dart';\n";
      final out = rule.apply(input);
      // header preserved
      expect(out, startsWith('/// docstring\nlibrary;'));
      expect(out.indexOf('alpha'), lessThan(out.indexOf('zeta')));
    });
  });
}
