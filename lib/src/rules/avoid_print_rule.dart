import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Fixes `avoid_print`: prepends `// ignore: avoid_print` above any line
/// that calls a top-level `print(...)`.
///
/// This is the conservative fix — it silences the lint without changing
/// runtime behaviour. Migration to a real logger is left to the developer.
///
/// Skips occurrences that are inside string literals or comments so the
/// rule does not fire on its own source or on test fixtures.
class AvoidPrintRule extends DeprecationRule {
  /// Creates a new [AvoidPrintRule].
  const AvoidPrintRule();

  @override
  String get name => 'avoidPrint';

  @override
  String get description => 'Silence avoid_print with an inline ignore';

  @override
  String get deprecatedPattern => 'unguarded print invocation';

  @override
  String get replacementExample => '// ignore: avoid_print';

  static final _printCall = RegExp(r'(^|[^.\w])print\s*\(', multiLine: true);

  @override
  bool matches(String content) {
    if (!_printCall.hasMatch(content)) {
      return false;
    }
    if (_hasFileLevelIgnore(content)) {
      return false;
    }
    return _findUnignoredPrintLines(content).isNotEmpty;
  }

  /// Returns true if the file already has a `// ignore_for_file: avoid_print`
  /// directive (with or without other lints listed).
  bool _hasFileLevelIgnore(String content) {
    final pattern = RegExp(
      r'//\s*ignore_for_file:\s*[^/\n]*\bavoid_print\b',
    );
    return pattern.hasMatch(content);
  }

  @override
  String apply(String content) {
    final unignored = _findUnignoredPrintLines(content);
    if (unignored.isEmpty) {
      return content;
    }
    final lines = content.split('\n');
    for (final lineIdx in unignored.toList().reversed) {
      final line = lines[lineIdx];
      final indent = RegExp(r'^\s*').firstMatch(line)!.group(0)!;
      lines
        ..insert(lineIdx, '$indent// ignore: avoid_print')
        ..insert(
          lineIdx,
          '$indent// Silenced by fix_deprecations; '
          'replace with a logger if needed.',
        );
    }
    return lines.join('\n');
  }

  /// Returns 0-based indices of lines with a real (non-string, non-comment)
  /// un-ignored `print(` invocation.
  Set<int> _findUnignoredPrintLines(String content) {
    final lines = content.split('\n');
    final result = <int>{};
    for (var i = 0; i < lines.length; i++) {
      final match = _printCall.firstMatch(lines[i]);
      if (match == null) {
        continue;
      }
      final trimmed = lines[i].trimLeft();
      if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
        continue;
      }
      if (_isInsideString(lines[i], match.start)) {
        continue;
      }
      final prev = i > 0 ? lines[i - 1].trim() : '';
      if (prev.contains('ignore:') && prev.contains('avoid_print')) {
        continue;
      }
      result.add(i);
    }
    return result;
  }

  /// Cheap heuristic: counts unescaped `'` and `"` on the line up to [pos]
  /// and reports whether either is unbalanced.
  bool _isInsideString(String line, int pos) {
    var single = 0;
    var doubleQ = 0;
    for (var i = 0; i < pos && i < line.length; i++) {
      if (i > 0 && line[i - 1] == r'\') {
        continue;
      }
      if (line[i] == "'") {
        single++;
      } else if (line[i] == '"') {
        doubleQ++;
      }
    }
    return single.isOdd || doubleQ.isOdd;
  }
}
