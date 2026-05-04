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
  static const List<DeprecationRule> allRules = [
    // Flutter / Material deprecations.
    WithOpacityRule(),
    SurfaceVariantRule(),
    OnSurfaceVariantRule(),
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

  /// Gets all available rule names.
  static List<String> get availableRuleNames {
    return allRules.map((rule) => rule.name).toList();
  }

  /// Gets rules by their names.
  ///
  /// If [ruleNames] is null or empty, returns all rules.
  /// Otherwise, returns only the rules matching the given names.
  static List<DeprecationRule> getRules(List<String>? ruleNames) {
    if (ruleNames == null || ruleNames.isEmpty) {
      return allRules;
    }

    final requestedRules = <DeprecationRule>[];
    final availableNames = availableRuleNames;

    for (final name in ruleNames) {
      final rule = allRules.firstWhere(
        (r) => r.name == name,
        orElse: () => throw ArgumentError(
          'Unknown rule: $name. Available rules: ${availableNames.join(', ')}',
        ),
      );
      requestedRules.add(rule);
    }

    return requestedRules;
  }

  /// Gets a single rule by name.
  static DeprecationRule? getRule(String name) {
    for (final rule in allRules) {
      if (rule.name == name) {
        return rule;
      }
    }
    return null;
  }

  /// Validates that all requested rule names are valid.
  static bool validateRuleNames(List<String> ruleNames) {
    final available = availableRuleNames.toSet();
    return ruleNames.every(available.contains);
  }

  /// Gets invalid rule names from the given list.
  static List<String> getInvalidRuleNames(List<String> ruleNames) {
    final available = availableRuleNames.toSet();
    return ruleNames.where((name) => !available.contains(name)).toList();
  }
}
