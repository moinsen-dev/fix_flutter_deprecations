import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Fixes `unreachable_from_main` for top-level test helpers by prepending
/// an `// ignore: unreachable_from_main` line above the declaration.
///
/// Heuristic: tags top-level function declarations whose names contain
/// telltale helper words (`mock`, `setup`, `helper`, `seed`, `fixture`,
/// `stub`, `fake`) when the file also contains a `main(...)`. Anything
/// else is left alone — the lint is too context-dependent to fix blindly.
class UnreachableFromMainRule extends DeprecationRule {
  /// Creates a new [UnreachableFromMainRule].
  const UnreachableFromMainRule();

  @override
  String get name => 'unreachableFromMain';

  @override
  String get description =>
      'Add an ignore comment above unreachable test helpers';

  @override
  String get deprecatedPattern => 'unreachable test helper';

  @override
  String get replacementExample => 'helper preceded by an ignore comment';

  static const _helperKeywords = [
    'mock',
    'setup',
    'helper',
    'seed',
    'fixture',
    'stub',
    'fake',
  ];

  // Function/method declaration at any indent level. Captures:
  //   1: leading whitespace (indent)
  //   2: return type fragment (with trailing whitespace)
  //   3: method name
  static final _topLevelFn = RegExp(
    r'^([ \t]*)(?:static\s+|@override\s+)*'
    r'([A-Za-z_][\w<>?,. ]*\s+)([a-zA-Z_]\w*)\s*\(',
    multiLine: true,
  );

  @override
  bool matches(String content) {
    if (!content.contains('main(')) {
      return false;
    }
    for (final match in _topLevelFn.allMatches(content)) {
      if (_isCandidate(content, match)) {
        return true;
      }
    }
    return false;
  }

  @override
  String apply(String content) {
    if (!content.contains('main(')) {
      return content;
    }
    final replacements = <_Insert>[];
    for (final match in _topLevelFn.allMatches(content)) {
      if (!_isCandidate(content, match)) {
        continue;
      }
      replacements.add(
        _Insert(
          at: _findLineStart(content, match.start),
          indent: match.group(1) ?? '',
        ),
      );
    }
    if (replacements.isEmpty) {
      return content;
    }
    final buffer = StringBuffer();
    var cursor = 0;
    for (final ins in replacements) {
      buffer
        ..write(content.substring(cursor, ins.at))
        ..write('${ins.indent}// ignore: unreachable_from_main\n');
      cursor = ins.at;
    }
    buffer.write(content.substring(cursor));
    return buffer.toString();
  }

  bool _isCandidate(String content, RegExpMatch match) {
    final name = match.group(3)!.toLowerCase();
    if (name == 'main') {
      return false;
    }
    final hasHelperWord = _helperKeywords.any(name.contains);
    if (!hasHelperWord) {
      return false;
    }
    final lineStart = _findLineStart(content, match.start);
    final prevEnd = lineStart - 1;
    if (prevEnd <= 0) {
      return true;
    }
    final prevStart = _findLineStart(content, prevEnd);
    final prev = content.substring(prevStart, prevEnd).trim();
    if (prev.contains('ignore:') && prev.contains('unreachable_from_main')) {
      return false;
    }
    return true;
  }

  int _findLineStart(String content, int index) {
    var i = index;
    while (i > 0 && content[i - 1] != '\n') {
      i--;
    }
    return i;
  }
}

class _Insert {
  _Insert({required this.at, required this.indent});
  final int at;
  final String indent;
}
