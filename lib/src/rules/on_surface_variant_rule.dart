import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Rule to fix deprecated onSurfaceVariant color.
///
/// Replaces `onSurfaceVariant` with `onSurface`.
class OnSurfaceVariantRule extends DeprecationRule {
  /// Creates a new [OnSurfaceVariantRule].
  const OnSurfaceVariantRule();

  @override
  String get name => 'onSurfaceVariant';

  @override
  String get description =>
      'Replace deprecated onSurfaceVariant with onSurface';

  @override
  String get deprecatedPattern => 'onSurfaceVariant';

  @override
  String get replacementExample => 'onSurface';

  /// Pattern to match onSurfaceVariant usage.
  /// Matches:
  /// - colorScheme.onSurfaceVariant
  /// - theme.colorScheme.onSurfaceVariant
  /// - Theme.of(context).colorScheme.onSurfaceVariant
  /// - color: onSurfaceVariant (in specific contexts)
  static final _pattern = RegExp(
    r'\bonSurfaceVariant\b',
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

    // Replace all occurrences of onSurfaceVariant with onSurface
    return content.replaceAll(_pattern, 'onSurface');
  }

  @override
  bool validate(String original, String modified) {
    // Call parent validation first
    if (!super.validate(original, modified)) {
      return false;
    }

    // Check that all onSurfaceVariant occurrences were replaced
    final modifiedCount = _pattern.allMatches(modified).length;

    // All onSurfaceVariant occurrences should be replaced
    if (modifiedCount != 0) {
      return false;
    }

    // Since onSurface is a common name that might already exist,
    // we can't reliably check the count of replacements
    // Just ensure no onSurfaceVariant remains
    return true;
  }
}
