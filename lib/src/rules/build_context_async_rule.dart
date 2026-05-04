import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Rule to fix use_build_context_synchronously lint warnings.
///
/// Adds mounted checks before using BuildContext after async operations.
/// This prevents using BuildContext when the widget is no longer in the tree.
class BuildContextAsyncRule extends DeprecationRule {
  /// Creates a new [BuildContextAsyncRule].
  const BuildContextAsyncRule();

  @override
  String get name => 'buildContextAsync';

  @override
  String get description =>
      'Add mounted checks for BuildContext usage after async gaps';

  @override
  String get deprecatedPattern => 'BuildContext after await';

  @override
  String get replacementExample => 'if (mounted) { /* use context */ }';

  /// Pattern to match Navigator operations with context after await.
  static final _navigatorPattern = RegExp(
    r'(await\s+[^;]+;)(\s*)(Navigator\.(?:of\s*\(\s*context\s*\)|push|pop|pushReplacement|pushNamed|pushAndRemoveUntil)[^;]*;)',
    multiLine: true,
  );

  /// Pattern to match showDialog/showModalBottomSheet after await.
  static final _showDialogPattern = RegExp(
    r'(await\s+[^;]+;)(\s*)((?:showDialog|showModalBottomSheet|showBottomSheet|showMenu|showSearch|showGeneralDialog|showCupertinoDialog|showCupertinoModalPopup)[\s\S]*?;)',
    multiLine: true,
  );

  /// Pattern to match ScaffoldMessenger operations after await.
  static final _scaffoldMessengerPattern = RegExp(
    r'(await\s+[^;]+;)(\s*)(ScaffoldMessenger\.of\s*\(\s*context\s*\)[^;]*;)',
    multiLine: true,
  );

  /// Pattern to match Theme/MediaQuery operations after await.
  static final _themePattern = RegExp(
    r'(await\s+[^;]+;)(\s*)((?:Theme|MediaQuery|Directionality|DefaultTextStyle)\.of\s*\(\s*context\s*\)[^;]*;)',
    multiLine: true,
  );

  /// Pattern to match direct context usage after await (simplified).
  static final _contextPattern = RegExp(
    r'(await\s+[^;]+;)(\s*)(\w+\.of\s*\(\s*context\s*\)[^;]*;)',
    multiLine: true,
  );

  /// Pattern to check if we're in a StatefulWidget.
  static final _statefulWidgetPattern = RegExp(
    r'class\s+\w+\s+extends\s+State<',
    multiLine: true,
  );

  /// Pattern to check if we're in a function that has BuildContext parameter.
  static final _buildContextParamPattern = RegExp(
    r'(?:Widget\s+build|[\w\s]+)\s*\(\s*(?:[\w\s,]*\s+)?BuildContext\s+(\w+)',
    multiLine: true,
  );

  @override
  bool matches(String content) {
    // Check if there are any async operations followed by context usage
    // that don't already have mounted checks
    return _hasUnprotectedMatch(content, _navigatorPattern) ||
        _hasUnprotectedMatch(content, _showDialogPattern) ||
        _hasUnprotectedMatch(content, _scaffoldMessengerPattern) ||
        _hasUnprotectedMatch(content, _themePattern) ||
        _hasUnprotectedMatch(content, _contextPattern);
  }

  /// Checks if pattern matches and the match doesn't already have a mounted
  /// check.
  bool _hasUnprotectedMatch(String content, RegExp pattern) {
    final matches = pattern.allMatches(content);
    for (final match in matches) {
      final fullMatch = match.group(0)!;
      final betweenPart = match.group(2) ?? '';

      // Check if there's already a mounted check
      if (!betweenPart.contains('mounted') &&
          !fullMatch.contains('if (mounted)') &&
          !fullMatch.contains('if (context.mounted)')) {
        return true;
      }
    }
    return false;
  }

  @override
  String apply(String content) {
    if (!matches(content)) {
      return content;
    }

    var result = content;

    // Determine if we're in a StatefulWidget or have BuildContext parameter
    final isStatefulWidget = _statefulWidgetPattern.hasMatch(content);
    final contextParamMatch = _buildContextParamPattern.firstMatch(content);
    final contextVarName = contextParamMatch?.group(1) ?? 'context';

    // Apply fixes for different patterns
    final patterns = [
      _navigatorPattern,
      _showDialogPattern,
      _scaffoldMessengerPattern,
      _themePattern,
      _contextPattern,
    ];

    for (final pattern in patterns) {
      result = _fixPattern(result, pattern, isStatefulWidget, contextVarName);
    }

    return result;
  }

  /// Fixes a specific pattern by adding mounted checks.
  String _fixPattern(
    String content,
    RegExp pattern,
    bool isStatefulWidget,
    String contextVarName,
  ) {
    return content.replaceAllMapped(pattern, (match) {
      final awaitPart = match.group(1)!;
      final whitespacePart = match.group(2)!;
      final contextUsage = match.group(3)!;

      // Check if there's already a mounted check nearby
      if (whitespacePart.contains('mounted') ||
          contextUsage.contains('mounted')) {
        return match.group(0)!;
      }

      // Determine the appropriate mounted check
      final mountedCheck = _getMountedCheck(
        contextUsage,
        isStatefulWidget,
        contextVarName,
      );

      // Extract indentation from the whitespace before context usage
      final lines = whitespacePart.split('\n');
      final lastLine = lines.last;
      final indentation = lastLine; // This should contain the indentation

      // Build the fixed code
      final buffer = StringBuffer()
        ..write(awaitPart)
        ..write('\n$indentation')
        ..write(mountedCheck)
        ..write(' {\n$indentation  ')
        ..write(contextUsage.trim())
        ..write('\n$indentation}');

      return buffer.toString();
    });
  }

  /// Gets the appropriate mounted check based on context.
  String _getMountedCheck(
    String contextUsage,
    bool isStatefulWidget,
    String contextVarName,
  ) {
    // For StatefulWidget, use mounted property
    if (isStatefulWidget) {
      return 'if (mounted)';
    }

    // For other contexts, check if context.mounted is available
    // This is available in Flutter 3.7+
    if (contextVarName == 'context') {
      return 'if (context.mounted)';
    } else {
      return 'if ($contextVarName.mounted)';
    }
  }

  @override
  bool validate(String original, String modified) {
    // Basic validation: ensure we didn't accidentally delete content
    if (modified.trim().isEmpty && original.trim().isNotEmpty) {
      return false;
    }

    // For this rule, we expect to add brackets (for if statements)
    // So we skip the bracket balance check and use a different approach

    // If content hasn't changed and there were matches, that's a problem
    if (original == modified && matches(original)) {
      return false;
    }

    // Check that we don't have any remaining unprotected patterns
    if (matches(modified)) {
      return false;
    }

    // Additional validation: ensure all added mounted checks have proper syntax
    final mountedChecks = RegExp(
      r'if\s*\(\s*(?:context\.)?mounted\s*\)\s*\{',
    ).allMatches(modified);

    // Each mounted check should have a corresponding closing brace
    for (final match in mountedChecks) {
      final checkStart = match.start;
      final afterCheck = modified.substring(checkStart);

      // Find the matching closing brace for the if statement
      final ifStart = afterCheck.indexOf('{');
      if (ifStart == -1) {
        return false; // No opening brace found
      }

      var braceCount = 0;
      var foundClosing = false;
      for (var i = ifStart; i < afterCheck.length; i++) {
        final char = afterCheck[i];
        if (char == '{') {
          braceCount++;
        } else if (char == '}') {
          braceCount--;
          if (braceCount == 0) {
            foundClosing = true;
            break;
          }
        }
      }

      if (!foundClosing) {
        return false;
      }
    }

    return true;
  }
}
