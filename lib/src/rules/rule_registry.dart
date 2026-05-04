import 'package:fix_flutter_deprecations/src/rules/avoid_print_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/build_context_async_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/cascade_invocations_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/control_body_new_line_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/flutter_style_todos_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/multiple_underscores_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/on_surface_variant_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/removed_lint_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/sort_pub_dependencies_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/strict_raw_type_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/surface_variant_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/unintended_html_doc_comment_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/unreachable_from_main_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/will_pop_scope_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/with_opacity_rule.dart';

/// Registry of all available deprecation rules.
class RuleRegistry {
  /// Private constructor to prevent instantiation.
  RuleRegistry._();

  /// All available deprecation rules.
  ///
  /// Note: `OnSurfaceVariantRule` is intentionally **not** part of the
  /// default set. `onSurfaceVariant` is still a distinct, valid color slot
  /// in Material 3 — the substitution is unsafe for code that uses both
  /// `onSurface` and `onSurfaceVariant`. The rule is still available via
  /// [optionalRules] for projects that explicitly want the migration.
  static const List<DeprecationRule> allRules = [
    // Flutter / Material deprecations.
    WithOpacityRule(),
    SurfaceVariantRule(),
    WillPopScopeRule(),
    // Lint rule fixes (Dart source files).
    MultipleUnderscoresRule(),
    BuildContextAsyncRule(),
    CascadeInvocationsRule(),
    ControlBodyNewLineRule(),
    AvoidPrintRule(),
    FlutterStyleTodosRule(),
    UnintendedHtmlDocCommentRule(),
    UnreachableFromMainRule(),
    StrictRawTypeRule(),
    // Project-config rules (yaml files).
    RemovedLintRule(),
    SortPubDependenciesRule(),
  ];

  /// Rules that are available via `--rules` but not enabled by default.
  /// They have a higher false-positive risk.
  static const List<DeprecationRule> optionalRules = [
    OnSurfaceVariantRule(),
  ];

  /// Default rules + optional rules — every rule the user can address by
  /// name via `--rules`.
  static List<DeprecationRule> get _addressableRules =>
      [...allRules, ...optionalRules];

  /// Gets all available rule names.
  static List<String> get availableRuleNames {
    return allRules.map((rule) => rule.name).toList();
  }

  /// Gets rules by their names.
  ///
  /// If [ruleNames] is null or empty, returns the default rule set.
  /// Otherwise, returns matching rules — including [optionalRules] when
  /// addressed by name.
  static List<DeprecationRule> getRules(List<String>? ruleNames) {
    if (ruleNames == null || ruleNames.isEmpty) {
      return allRules;
    }

    final requestedRules = <DeprecationRule>[];
    final addressable = _addressableRules;
    final addressableNames = addressable.map((r) => r.name).toList();

    for (final name in ruleNames) {
      final rule = addressable.firstWhere(
        (r) => r.name == name,
        orElse: () => throw ArgumentError(
          'Unknown rule: $name. '
          'Available rules: ${addressableNames.join(', ')}',
        ),
      );
      requestedRules.add(rule);
    }

    return requestedRules;
  }

  /// Gets a single rule by name (default + optional).
  static DeprecationRule? getRule(String name) {
    for (final rule in _addressableRules) {
      if (rule.name == name) {
        return rule;
      }
    }
    return null;
  }

  /// Validates that all requested rule names are valid (default or optional).
  static bool validateRuleNames(List<String> ruleNames) {
    final available = _addressableRules.map((r) => r.name).toSet();
    return ruleNames.every(available.contains);
  }

  /// Gets invalid rule names from the given list.
  static List<String> getInvalidRuleNames(List<String> ruleNames) {
    final available = _addressableRules.map((r) => r.name).toSet();
    return ruleNames.where((name) => !available.contains(name)).toList();
  }
}
