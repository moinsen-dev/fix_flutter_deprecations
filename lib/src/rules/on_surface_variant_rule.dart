import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Rule to fix deprecated onSurface color.
///
/// Replaces `onSurface` with `onSurface`.
class OnSurfaceVariantRule extends DeprecationRule {
  /// Creates a new [OnSurfaceVariantRule].
  const OnSurfaceVariantRule();

  @override
  String get name => 'onSurface';

  @override
  // Strings assembled at runtime so this rule cannot rewrite its own source.
  String get description {
    const a = 'onSurface';
    const b = 'Variant';
    return 'Replace deprecated $a$b with onSurface';
  }

  @override
  String get deprecatedPattern {
    const a = 'onSurface';
    const b = 'Variant';
    return '$a$b';
  }

  @override
  String get replacementExample => 'onSurface';

  /// Pattern to match onSurface usage.
  /// Matches:
  /// - colorScheme.onSurface
  /// - theme.colorScheme.onSurface
  /// - Theme.of(context).colorScheme.onSurface
  /// - color: onSurface (in specific contexts)
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

    // Replace all occurrences of onSurface with onSurface
    return content.replaceAll(_pattern, 'onSurface');
  }

  @override
  bool validate(String original, String modified) {
    // Call parent validation first
    if (!super.validate(original, modified)) {
      return false;
    }

    // Check that all onSurface occurrences were replaced
    final modifiedCount = _pattern.allMatches(modified).length;

    // All onSurface occurrences should be replaced
    if (modifiedCount != 0) {
      return false;
    }

    // Since onSurface is a common name that might already exist,
    // we can't reliably check the count of replacements
    // Just ensure no onSurface remains
    return true;
  }
}
