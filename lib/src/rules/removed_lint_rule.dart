import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Fixes `removed_lint` warnings in `analysis_options.yaml` by removing
/// known retired lint names.
class RemovedLintRule extends DeprecationRule {
  /// Creates a new [RemovedLintRule].
  const RemovedLintRule();

  @override
  String get name => 'removedLint';

  @override
  String get description =>
      'Remove retired lint names from analysis_options.yaml';

  @override
  String get deprecatedPattern => 'removed lint name';

  @override
  String get replacementExample => '(line removed)';

  @override
  Set<String> get appliesToExtensions => const {'analysis_options.yaml'};

  /// Hand-curated list of removed lints.
  /// Source: https://dart.dev/tools/linter-rules/removed
  static const removedLints = <String>{
    // Dart 3.7
    'package_api_docs',
    // Dart 3.5
    'iterable_contains_unrelated_type',
    'list_remove_unrelated_type',
    // Dart 3.4
    'enable_null_safety',
    'invariant_booleans',
    'prefer_bool_in_asserts',
    'prefer_equal_for_default_values',
    'super_goes_last',
    // Dart 3.3
    'always_require_non_null_named_parameters',
    'avoid_returning_null',
    'avoid_returning_null_for_future',
    // Dart 2 era
    'always_specify_types_for_local_variables',
    'unsafe_html',
  };

  @override
  bool matches(String content) {
    return _findRemovedLintLines(content).isNotEmpty;
  }

  @override
  String apply(String content) {
    final toRemove = _findRemovedLintLines(content);
    if (toRemove.isEmpty) {
      return content;
    }
    final lines = content.split('\n');
    final keep = <String>[];
    for (var i = 0; i < lines.length; i++) {
      if (toRemove.contains(i)) {
        continue;
      }
      keep.add(lines[i]);
    }
    return keep.join('\n');
  }

  Set<int> _findRemovedLintLines(String content) {
    final result = <int>{};
    final lines = content.split('\n');
    final pattern = RegExp(r'^\s*-?\s*([a-z_]+)\s*:?');
    for (var i = 0; i < lines.length; i++) {
      final match = pattern.firstMatch(lines[i]);
      if (match == null) {
        continue;
      }
      final name = match.group(1)!;
      if (removedLints.contains(name)) {
        result.add(i);
      }
    }
    return result;
  }
}
