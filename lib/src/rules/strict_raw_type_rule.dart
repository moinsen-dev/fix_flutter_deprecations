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

  // Bare collection types used as a generic argument — captured groups
  // re-emit the surrounding `<…>` so we replace only the inner type.
  static final _mapAsGenericArg = RegExp(r'(<\s*)Map(\s*[,>])');
  static final _listAsGenericArg = RegExp(r'(<\s*)List(\s*[,>])');

  @override
  bool matches(String content) =>
      _mapDynDyn.hasMatch(content) ||
      _mapAsGenericArg.hasMatch(content) ||
      _listAsGenericArg.hasMatch(content);

  @override
  String apply(String content) {
    if (!matches(content)) {
      return content;
    }
    var out = content.replaceAll(_mapDynDyn, 'Map<String, dynamic>');
    out = out.replaceAllMapped(
      _mapAsGenericArg,
      (m) => '${m.group(1)}Map<String, dynamic>${m.group(2)}',
    );
    out = out.replaceAllMapped(
      _listAsGenericArg,
      (m) => '${m.group(1)}List<dynamic>${m.group(2)}',
    );
    return out;
  }
}
