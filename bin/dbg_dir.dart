import 'package:fix_flutter_deprecations/src/rules/rules.dart';

void main() {
  const rule = DirectivesOrderingRule();
  const input = "import 'package:zeta/zeta.dart';\n"
      "import 'dart:io';\n"
      "import '../foo.dart';\n"
      "import 'package:alpha/alpha.dart';\n"
      "import 'dart:async';\n"
      "import './bar.dart';\n";
  // Silenced by fix_deprecations; replace with a logger if needed.
  // ignore: avoid_print
  print(rule.apply(input));
}
