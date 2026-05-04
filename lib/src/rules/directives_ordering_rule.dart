import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Fixes `directives_ordering`: alphabetically sorts `import` and `export`
/// directives inside their three groups: `dart:`, `package:`, and
/// relative imports.
///
/// The rule operates on a contiguous block of directives at the top of
/// the file (after `library` / leading comments). It does **not**
/// reorder directives across groups — only within each group, alphabetically.
class DirectivesOrderingRule extends DeprecationRule {
  /// Creates a new [DirectivesOrderingRule].
  const DirectivesOrderingRule();

  @override
  String get name => 'directivesOrdering';

  @override
  String get description =>
      'Alphabetically sort import/export directives within their groups';

  @override
  String get deprecatedPattern => 'unsorted import directives';

  @override
  String get replacementExample => 'sorted import directives';

  static final _directiveStart = RegExp(r'^\s*(import|export)\b');

  @override
  bool matches(String content) {
    final block = _findDirectiveBlock(content);
    if (block == null) {
      return false;
    }
    final entries = _parseEntries(content, block);
    return _isUnsorted(entries);
  }

  @override
  String apply(String content) {
    final block = _findDirectiveBlock(content);
    if (block == null) {
      return content;
    }
    final entries = _parseEntries(content, block);
    if (!_isUnsorted(entries)) {
      return content;
    }

    // Sort within groups, preserving the original group order.
    entries.sort((a, b) {
      final groupCmp = a.group.index.compareTo(b.group.index);
      if (groupCmp != 0) {
        return groupCmp;
      }
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });

    final lines = content.split('\n');
    final newDirectiveLines = <String>[];
    _Group? lastGroup;
    for (final e in entries) {
      // Insert a blank line between groups (matches common Dart style).
      if (lastGroup != null && lastGroup != e.group) {
        newDirectiveLines.add('');
      }
      newDirectiveLines.addAll(e.lines);
      lastGroup = e.group;
    }

    final result = <String>[
      ...lines.sublist(0, block.start),
      ...newDirectiveLines,
      ...lines.sublist(block.end + 1),
    ];
    return result.join('\n');
  }

  /// Find the contiguous run of directive lines (with their continuations
  /// and intervening blank lines) at the top of the file.
  _Range? _findDirectiveBlock(String content) {
    final lines = content.split('\n');
    var start = -1;
    var end = -1;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_directiveStart.hasMatch(line)) {
        start = i;
        end = _findDirectiveEnd(lines, i);
        break;
      }
      if (line.trim().isEmpty) {
        continue;
      }
      // Skip leading comments and `library;` declaration.
      final trimmed = line.trim();
      if (trimmed.startsWith('//') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*') ||
          trimmed.startsWith('@') ||
          trimmed.startsWith('library')) {
        continue;
      }
      // First non-directive, non-comment line — no directive block.
      return null;
    }
    if (start < 0) {
      return null;
    }
    // Extend the block forward over additional directive runs separated
    // only by blank lines.
    var i = end + 1;
    while (i < lines.length) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        i++;
        continue;
      }
      if (_directiveStart.hasMatch(line)) {
        end = _findDirectiveEnd(lines, i);
        i = end + 1;
        continue;
      }
      break;
    }
    return _Range(start, end);
  }

  int _findDirectiveEnd(List<String> lines, int startIdx) {
    var i = startIdx;
    while (i < lines.length) {
      // A directive ends at the first line whose trimmed form ends with `;`.
      if (lines[i].trimRight().endsWith(';')) {
        return i;
      }
      i++;
    }
    return lines.length - 1;
  }

  List<_Entry> _parseEntries(String content, _Range block) {
    final lines = content.split('\n');
    final entries = <_Entry>[];
    var i = block.start;
    while (i <= block.end) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        i++;
        continue;
      }
      if (!_directiveStart.hasMatch(line)) {
        i++;
        continue;
      }
      final endIdx = _findDirectiveEnd(lines, i);
      final entryLines = lines.sublist(i, endIdx + 1);
      final pathMatch = RegExp("['\"]([^'\"]+)['\"]")
          .firstMatch(entryLines.join(' '));
      final path = pathMatch?.group(1) ?? '';
      entries.add(
        _Entry(
          path: path,
          group: _classify(path),
          lines: entryLines,
        ),
      );
      i = endIdx + 1;
    }
    return entries;
  }

  _Group _classify(String path) {
    if (path.startsWith('dart:')) {
      return _Group.dart;
    }
    if (path.startsWith('package:')) {
      return _Group.pkg;
    }
    return _Group.relative;
  }

  bool _isUnsorted(List<_Entry> entries) {
    for (var i = 1; i < entries.length; i++) {
      final prev = entries[i - 1];
      final cur = entries[i];
      // Group transitions are fine; only flag unsorted within a group.
      if (prev.group != cur.group) {
        continue;
      }
      if (prev.path.toLowerCase().compareTo(cur.path.toLowerCase()) > 0) {
        return true;
      }
    }
    // Also flag if the groups appear in the wrong order overall.
    final actualGroupOrder = <int>[];
    for (final e in entries) {
      if (actualGroupOrder.isEmpty ||
          actualGroupOrder.last != e.group.index) {
        actualGroupOrder.add(e.group.index);
      }
    }
    for (var i = 1; i < actualGroupOrder.length; i++) {
      if (actualGroupOrder[i - 1] > actualGroupOrder[i]) {
        return true;
      }
    }
    return false;
  }
}

enum _Group { dart, pkg, relative }

class _Range {
  _Range(this.start, this.end);
  final int start;
  final int end;
}

class _Entry {
  _Entry({required this.path, required this.group, required this.lines});
  final String path;
  final _Group group;
  final List<String> lines;
}
