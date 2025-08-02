import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Rule to fix deprecated surfaceVariant color.
///
/// Replaces `surfaceVariant` with `surfaceContainerHighest`.
class SurfaceVariantRule extends DeprecationRule {
  /// Creates a new [SurfaceVariantRule].
  const SurfaceVariantRule();

  @override
  String get name => 'surfaceVariant';

  @override
  String get description =>
      'Replace deprecated surfaceVariant with surfaceContainerHighest';

  @override
  String get deprecatedPattern => 'surfaceVariant';

  @override
  String get replacementExample => 'surfaceContainerHighest';

  /// Pattern to match surfaceVariant usage.
  /// Matches:
  /// - colorScheme.surfaceVariant
  /// - theme.colorScheme.surfaceVariant
  /// - Theme.of(context).colorScheme.surfaceVariant
  /// - color: surfaceVariant (in specific contexts)
  static final _pattern = RegExp(
    r'\bsurfaceVariant\b',
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

    // Replace all occurrences of surfaceVariant with surfaceContainerHighest
    return content.replaceAll(_pattern, 'surfaceContainerHighest');
  }

  @override
  bool validate(String original, String modified) {
    // Call parent validation first
    if (!super.validate(original, modified)) {
      return false;
    }

    // Check that we replaced the expected number of occurrences
    final originalCount = _pattern.allMatches(original).length;
    final modifiedCount = _pattern.allMatches(modified).length;

    // All surfaceVariant occurrences should be replaced
    if (modifiedCount != 0) {
      return false;
    }

    // Check that surfaceContainerHighest appears the expected number of times
    final replacementPattern = RegExp(r'\bsurfaceContainerHighest\b');
    final replacementCount = replacementPattern.allMatches(modified).length;

    // Account for existing surfaceContainerHighest in original
    final existingReplacementCount = replacementPattern
        .allMatches(original)
        .length;

    return replacementCount == originalCount + existingReplacementCount;
  }
}
