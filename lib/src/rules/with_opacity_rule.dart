import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Rule to fix deprecated .withOpacity() calls.
///
/// Replaces `.withValues(alpha: value)` with `.withValues(alpha: value)`.
class WithOpacityRule extends DeprecationRule {
  /// Creates a new [WithOpacityRule].
  const WithOpacityRule();

  @override
  String get name => 'withOpacity';

  @override
  String get description =>
      'Replace deprecated .withOpacity() with .withValues(alpha:)';

  @override
  String get deprecatedPattern => r'\.withOpacity\(';

  @override
  String get replacementExample => '.withValues(alpha: value)';

  /// Pattern to match .withValues(alpha: value) calls.
  static final _pattern = RegExp(
    r'\.withOpacity\s*\(\s*([^)]+)\s*\)',
    multiLine: true,
  );

  @override
  bool matches(String content) {
    return _pattern.hasMatch(content);
  }

  @override
  String apply(String content) {
    if (!matches(content)) {
      return content;
    }

    return content.replaceAllMapped(_pattern, (match) {
      final opacityValue = match.group(1)!.trim();
      return '.withValues(alpha: $opacityValue)';
    });
  }

  @override
  bool validate(String original, String modified) {
    // Call parent validation first
    if (!super.validate(original, modified)) {
      return false;
    }

    // Additional validation: ensure we didn't break method chains
    final originalLines = original.split('\n').length;
    final modifiedLines = modified.split('\n').length;

    // Line count should remain the same
    if (originalLines != modifiedLines) {
      return false;
    }

    // Ensure all withOpacity calls were replaced
    if (matches(modified)) {
      return false;
    }

    return true;
  }
}
