import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Rule to fix deprecated WillPopScope widget.
///
/// Replaces `WillPopScope` with `PopScope` and updates the callback signature.
///
/// The migration involves:
/// 1. Renaming WillPopScope to PopScope
/// 2. Changing onWillPop callback from `Future<bool> Function()` to
///    void Function(bool didPop, dynamic result) with canPop property
class WillPopScopeRule extends DeprecationRule {
  /// Creates a new [WillPopScopeRule].
  const WillPopScopeRule();

  @override
  String get name => 'willPopScope';

  @override
  String get description =>
      'Replace deprecated WillPopScope with PopScope for predictive '
      'back support';

  @override
  String get deprecatedPattern => 'WillPopScope';

  @override
  String get replacementExample => 'PopScope';

  /// Pattern to match WillPopScope widget usage.
  static final _widgetPattern = RegExp(
    r'WillPopScope\s*\(',
    multiLine: true,
  );

  /// Pattern to match onWillPop callback.
  static final _onWillPopPattern = RegExp(
    r'onWillPop\s*:\s*(\([^)]*\))?\s*(?:async\s*)?\{([^}]+)\}',
    multiLine: true,
    dotAll: true,
  );

  /// Pattern to match simple arrow function onWillPop.
  static final _onWillPopArrowPattern = RegExp(
    r'onWillPop\s*:\s*\(\)\s*(?:async\s*)?=>\s*([^,]+)(?=,|\s*\))',
    multiLine: true,
  );

  @override
  bool matches(String content) {
    return _widgetPattern.hasMatch(content);
  }

  @override
  String apply(String content) {
    if (!matches(content)) {
      return content;
    }

    // First, replace WillPopScope with PopScope
    var result = content.replaceAll('WillPopScope', 'PopScope');

    // Handle arrow function pattern
    result = result.replaceAllMapped(_onWillPopArrowPattern, (match) {
      final returnExpression = match.group(1)!.trim();

      // If it's a simple true/false return, convert to canPop
      if (returnExpression == 'true' || returnExpression == 'false') {
        return 'canPop: $returnExpression';
      }

      // For more complex expressions, create onPopInvoked callback
      return '''
canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        final bool shouldPop = await ($returnExpression);
        if (shouldPop) {
          navigator.pop();
        }
      }''';
    });

    // Handle block function pattern
    result = result.replaceAllMapped(_onWillPopPattern, (match) {
      final body = match.group(2)!.trim();

      // Check if body is a simple return statement
      final simpleReturnMatch = RegExp(
        r'^\s*return\s+(true|false)\s*;?\s*$',
      ).firstMatch(body);
      if (simpleReturnMatch != null) {
        final value = simpleReturnMatch.group(1);
        return 'canPop: $value';
      }

      // For complex logic, convert to onPopInvoked
      // Extract the return value logic
      final returnMatch = RegExp(r'return\s+([^;]+);').firstMatch(body);
      if (returnMatch != null) {
        final returnExpression = returnMatch.group(1)!.trim();
        final bodyWithoutReturn = body
            .replaceAll(returnMatch.group(0)!, '')
            .trim();

        // Check if the return expression references a variable
        // that's already defined
        final variablePattern = RegExp(r'^(\w+)(?:\s*\?\?\s*.+)?$');
        final variableMatch = variablePattern.firstMatch(returnExpression);

        if (variableMatch != null) {
          final variableName = variableMatch.group(1)!;
          // Check if this variable is defined in the body
          final isVariableDefined = RegExp(
            '\\b(?:final|const|var)?\\s*(?:\\w+\\s+)?$variableName\\s*=',
          ).hasMatch(bodyWithoutReturn);

          if (isVariableDefined) {
            // Variable is already defined, use it directly
            return '''
canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        $bodyWithoutReturn
        if ($returnExpression) {
          navigator.pop();
        }
      }''';
          }
        }

        // Variable is not defined or return expression is complex
        return '''
canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        $bodyWithoutReturn
        final bool shouldPop = await $returnExpression;
        if (shouldPop) {
          navigator.pop();
        }
      }''';
      }

      // Fallback for other patterns
      return '''
canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        $body
      }''';
    });

    return result;
  }

  @override
  bool validate(String original, String modified) {
    // Call parent validation first
    if (!super.validate(original, modified)) {
      return false;
    }

    // Ensure all WillPopScope instances were replaced
    if (matches(modified)) {
      return false;
    }

    // Ensure PopScope is now present
    if (!modified.contains('PopScope')) {
      return false;
    }

    return true;
  }
}
