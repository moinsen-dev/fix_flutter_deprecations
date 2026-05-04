import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Fixes `always_put_control_body_on_new_line`: splits inline
/// `if (cond) statement;` style constructs onto two lines.
///
/// Handles `if`, `for`, `while`. Bodies that are blocks (`{ … }`) or
/// chained control statements are left untouched.
class ControlBodyNewLineRule extends DeprecationRule {
  /// Creates a new [ControlBodyNewLineRule].
  const ControlBodyNewLineRule();

  @override
  String get name => 'controlBodyNewLine';

  @override
  String get description =>
      'Move single-statement if/for/while bodies onto a new line';

  @override
  String get deprecatedPattern => 'inline single-statement control body';

  @override
  String get replacementExample => 'body on its own indented line';

  static final _inlineCtrl = RegExp(
    r'^([ \t]*)(if|for|while)\s*\((.*)\)\s+([^\s{].*?;)\s*$',
    multiLine: true,
  );

  @override
  bool matches(String content) {
    return _inlineCtrl.allMatches(content).any(_isFixable);
  }

  @override
  String apply(String content) {
    return content.replaceAllMapped(_inlineCtrl, (match) {
      if (!_isFixable(match)) {
        return match.group(0)!;
      }
      final indent = match.group(1)!;
      final keyword = match.group(2)!;
      final cond = match.group(3)!;
      final body = match.group(4)!;
      // Emit a braced 3-line form so we satisfy both
      // `always_put_control_body_on_new_line` and
      // `curly_braces_in_flow_control_structures`.
      return '$indent$keyword ($cond) {\n$indent  $body\n$indent}';
    });
  }

  bool _isFixable(Match match) {
    final cond = match.group(3)!;
    final opens = '('.allMatches(cond).length;
    final closes = ')'.allMatches(cond).length;
    if (opens != closes) {
      return false;
    }
    final body = match.group(4)!.trim();
    if (RegExp(r'^(if|for|while|do)\b').hasMatch(body)) {
      return false;
    }
    if (body.startsWith(')') || body.startsWith(',')) {
      return false;
    }
    return true;
  }
}
