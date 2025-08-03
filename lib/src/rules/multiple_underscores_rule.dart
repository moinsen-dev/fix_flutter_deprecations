import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Rule to fix unnecessary use of multiple underscores in identifiers.
///
/// Replaces identifiers with multiple leading underscores (e.g., `_variable`,
/// `_method`) with a single underscore (e.g., `_variable`, `_method`).
///
/// This follows the Dart style guide which recommends using only a single
/// underscore for private members.
class MultipleUnderscoresRule extends DeprecationRule {
  /// Creates a new [MultipleUnderscoresRule].
  const MultipleUnderscoresRule();

  @override
  String get name => 'multipleUnderscores';

  @override
  String get description =>
      'Replace multiple leading underscores with a single underscore';

  @override
  String get deprecatedPattern => '__+';

  @override
  String get replacementExample => '_';

  /// Pattern to match identifiers with multiple leading underscores.
  /// Matches variable declarations, method names, class names, etc.
  static final _identifierPattern = RegExp(
    r'\b(__+)(\w+)\b',
    multiLine: true,
  );

  /// Pattern to match constructor parameters with multiple underscores.
  static final _constructorParamPattern = RegExp(
    r'(this\.)(__+)(\w+)',
    multiLine: true,
  );

  /// Pattern to match named parameters with multiple underscores.
  static final _namedParamPattern = RegExp(
    r'(\{[^}]*?)(__+)(\w+)(\s*:)',
    multiLine: true,
  );

  @override
  bool matches(String content) {
    return _identifierPattern.hasMatch(content) ||
        _constructorParamPattern.hasMatch(content) ||
        _namedParamPattern.hasMatch(content);
  }

  @override
  String apply(String content) {
    if (!matches(content)) {
      return content;
    }

    var result = content;

    // Replace standard identifiers with multiple underscores
    result = result.replaceAllMapped(_identifierPattern, (match) {
      final underscores = match.group(1)!;
      final identifier = match.group(2)!;

      // Check if this is a special case that should be preserved
      if (_shouldPreserveIdentifier(underscores, identifier)) {
        return match.group(0)!;
      }

      return '_$identifier';
    });

    // Replace constructor parameters with multiple underscores
    result = result.replaceAllMapped(_constructorParamPattern, (match) {
      final prefix = match.group(1)!;
      final identifier = match.group(3)!;
      return '${prefix}_$identifier';
    });

    // Replace named parameters with multiple underscores
    result = result.replaceAllMapped(_namedParamPattern, (match) {
      final prefix = match.group(1)!;
      final identifier = match.group(3)!;
      final suffix = match.group(4)!;
      return '${prefix}_$identifier$suffix';
    });

    return result;
  }

  /// Checks if an identifier should be preserved (not modified).
  ///
  /// Some identifiers might use multiple underscores intentionally,
  /// such as generated code or special markers.
  bool _shouldPreserveIdentifier(String underscores, String identifier) {
    // Preserve identifiers that might be generated code markers
    if (identifier.startsWith('GENERATED') ||
        identifier.startsWith('AUTO') ||
        identifier.contains('MOCK')) {
      return true;
    }

    // Preserve test-specific patterns like __$ClassName
    if (identifier.startsWith(r'$')) {
      return true;
    }

    return false;
  }

  @override
  bool validate(String original, String modified) {
    // Basic validation: ensure we didn't accidentally delete content
    if (modified.trim().isEmpty && original.trim().isNotEmpty) {
      return false;
    }

    // Additional validation: ensure we didn't break any syntax
    // Count occurrences of various brackets to ensure balance
    final originalBrackets = _countBrackets(original);
    final modifiedBrackets = _countBrackets(modified);

    // Compare bracket counts
    for (final bracket in originalBrackets.keys) {
      if (originalBrackets[bracket] != modifiedBrackets[bracket]) {
        return false;
      }
    }

    // If the content hasn't changed and there were no matches, that's valid
    if (original == modified) {
      return !matches(original);
    }

    // If content was modified, that should be considered valid
    // We trust that the apply method did its job correctly
    // The only case we want to catch is if the rule claims to have fixed
    // something but didn't actually change anything when it should have
    if (matches(original) && original == modified) {
      return false;
    }

    return true;
  }

  /// Counts brackets in the content to ensure syntax isn't broken.
  Map<String, int> _countBrackets(String content) {
    return {
      '(': content.split('(').length - 1,
      ')': content.split(')').length - 1,
      '{': content.split('{').length - 1,
      '}': content.split('}').length - 1,
      '[': content.split('[').length - 1,
      ']': content.split(']').length - 1,
    };
  }
}
