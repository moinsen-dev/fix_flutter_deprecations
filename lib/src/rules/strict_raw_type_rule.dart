import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Fixes `strict_raw_type`: replaces a few well-known raw generic types
/// with sensible defaults.
///
/// Conservative substitutions only. Anything unknown is left alone.
class StrictRawTypeRule extends DeprecationRule {
  /// Creates a new [StrictRawTypeRule].
  const StrictRawTypeRule();

  @override
  String get name => 'strictRawType';

  @override
  String get description =>
      'Replace common raw generic types with explicit type arguments';

  @override
  // Assembled at runtime so this rule cannot rewrite its own source.
  String get deprecatedPattern {
    const a = 'dyn';
    const b = 'amic';
    return 'Map<$a$b, $a$b>';
  }

  @override
  String get replacementExample => 'Map<String, dynamic>';

  static final _mapDynDyn = RegExp(r'\bMap<\s*dynamic\s*,\s*dynamic\s*>');

  @override
  bool matches(String content) => _mapDynDyn.hasMatch(content);

  @override
  String apply(String content) {
    if (!matches(content)) {
      return content;
    }
    return content.replaceAll(_mapDynDyn, 'Map<String, dynamic>');
  }
}
