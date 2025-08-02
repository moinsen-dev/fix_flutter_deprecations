import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/on_surface_variant_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/surface_variant_rule.dart';
import 'package:fix_flutter_deprecations/src/rules/with_opacity_rule.dart';

/// Registry of all available deprecation rules.
class RuleRegistry {
  /// Private constructor to prevent instantiation.
  RuleRegistry._();

  /// All available deprecation rules.
  static const List<DeprecationRule> allRules = [
    WithOpacityRule(),
    SurfaceVariantRule(),
    OnSurfaceVariantRule(),
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
