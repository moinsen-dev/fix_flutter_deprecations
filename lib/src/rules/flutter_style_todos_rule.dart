import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Fixes `flutter_style_todos`: rewrites unnamed todo comments to the
/// `(unassigned)` Flutter style.
///
/// Already-tagged comments (with a name in parentheses) are left
/// untouched.
class FlutterStyleTodosRule extends DeprecationRule {
  /// Creates a new [FlutterStyleTodosRule].
  const FlutterStyleTodosRule();

  @override
  String get name => 'flutterStyleTodos';

  @override
  String get description => 'Rewrite unnamed TODO comments to Flutter style';

  @override
  String get deprecatedPattern => 'unnamed todo comment';

  @override
  String get replacementExample => 'todo comment with (unassigned) tag';

  // Matches either `//` or `///` followed by an unnamed TODO. Group 2
  // captures the slashes so we preserve the original comment kind.
  static final _untaggedTodo = RegExp(
    r'(^|\s)(///?)\s*TODO\s*:',
    multiLine: true,
  );

  @override
  bool matches(String content) => _untaggedTodo.hasMatch(content);

  @override
  String apply(String content) {
    if (!matches(content)) {
      return content;
    }
    return content.replaceAllMapped(_untaggedTodo, (match) {
      final lead = match.group(1) ?? '';
      final slashes = match.group(2)!;
      return '$lead$slashes TODO(unassigned):';
    });
  }
}
