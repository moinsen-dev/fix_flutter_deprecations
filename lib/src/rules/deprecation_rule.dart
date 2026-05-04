import 'package:meta/meta.dart';

/// Abstract base class for defining Flutter deprecation fix rules.
///
/// This class provides the foundation for implementing specific deprecation
/// fix rules. Each rule defines how to identify deprecated code patterns
/// and transform them to their modern equivalents.
///
/// ## Example Implementation
///
/// ```dart
/// class WithOpacityRule extends DeprecationRule {
///   @override
///   String get name => 'withOpacity';
///
///   @override
///   String get description =>
///       'Replace .withOpacity() with .withValues(alpha:)';
///
///   @override
///   String get deprecatedPattern => r'\.withOpacity\(';
///
///   @override
///   String get replacementExample => '.withValues(alpha: opacity)';
///
///   @override
///   bool matches(String content) =>
///       content.contains(RegExp(deprecatedPattern));
///
///   @override
///   String apply(String content) {
///     // Implementation specific logic
///     return transformedContent;
///   }
/// }
/// ```
///
/// ## Rule Lifecycle
///
/// 1. **Detection**: [matches] determines if deprecated code exists
/// 2. **Transformation**: [apply] performs the actual code changes
/// 3. **Validation**: [validate] ensures the transformation is safe
/// 4. **Analysis**: [analyzeChanges] provides detailed change reports
abstract class DeprecationRule {
  /// Creates a new [DeprecationRule].
  const DeprecationRule();

  /// The unique name of this rule.
  String get name;

  /// A human-readable description of what this rule fixes.
  String get description;

  /// The pattern that identifies the deprecated code.
  String get deprecatedPattern;

  /// An example of the replacement pattern.
  String get replacementExample;

  /// File extensions this rule applies to.
  ///
  /// Most rules apply to Dart source files (`.dart`). Rules targeting
  /// project configuration (e.g. `pubspec.yaml`, `analysis_options.yaml`)
  /// override this to declare their target extensions.
  Set<String> get appliesToExtensions => const {'.dart'};

  /// Checks if this rule applies to the given content.
  ///
  /// This method scans the provided [content] for patterns that match
  /// the deprecated code this rule is designed to fix.
  ///
  /// Parameters:
  /// - [content]: The source code content to analyze
  ///
  /// Returns `true` if the content contains the deprecated pattern that
  /// this rule can fix, `false` otherwise.
  bool matches(String content);

  /// Applies this rule to the given content.
  ///
  /// This method performs the actual transformation of deprecated code
  /// patterns to their modern equivalents. It should only be called
  /// after [matches] returns `true`.
  ///
  /// Parameters:
  /// - [content]: The source code content to transform
  ///
  /// Returns the modified content with deprecations fixed. If no
  /// deprecated patterns are found, returns the original content unchanged.
  ///
  /// Throws:
  /// - [StateError]: If the content cannot be safely transformed
  String apply(String content);

  /// Validates that the transformation is safe.
  ///
  /// This method performs safety checks to ensure that the transformation
  /// from [original] to [modified] content preserves the intended
  /// functionality and doesn't introduce errors.
  ///
  /// Parameters:
  /// - [original]: The original source code content
  /// - [modified]: The transformed source code content
  ///
  /// Returns `true` if the transformation is safe and preserves
  /// functionality, `false` if issues are detected.
  bool validate(String original, String modified) {
    // Basic validation: ensure content was actually modified
    if (original == modified) {
      return !matches(original);
    }

    // Ensure we didn't accidentally delete the entire content
    if (modified.trim().isEmpty && original.trim().isNotEmpty) {
      return false;
    }

    return true;
  }

  /// Returns a detailed report of changes that would be made.
  @protected
  List<String> analyzeChanges(String content) {
    final changes = <String>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      if (matches(lines[i])) {
        changes.add('Line ${i + 1}: $deprecatedPattern → $replacementExample');
      }
    }

    return changes;
  }
}
