import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Fixes `sort_pub_dependencies` by alphabetically sorting the entries
/// inside `dependencies:`, `dev_dependencies:` and `dependency_overrides:`
/// blocks of `pubspec.yaml`.
///
/// Implementation is line-based to preserve comments, blank lines and
/// surrounding file shape. A "block entry" is the dependency name plus
/// any indented continuation lines that follow it.
class SortPubDependenciesRule extends DeprecationRule {
  /// Creates a new [SortPubDependenciesRule].
  const SortPubDependenciesRule();

  @override
  String get name => 'sortPubDependencies';

  @override
  String get description => 'Alphabetically sort dependencies in pubspec.yaml';

  @override
  String get deprecatedPattern => 'unsorted dependencies';

  @override
  String get replacementExample => 'sorted dependencies';

  @override
  Set<String> get appliesToExtensions => const {'pubspec.yaml'};

  static const _blockHeaders = <String>{
    'dependencies:',
    'dev_dependencies:',
    'dependency_overrides:',
  };

  static final _keyPattern = RegExp(r'^\s*([a-zA-Z_][\w-]*)');
  static final _whitespace = RegExp(r'\s');

  @override
  bool matches(String content) => _hasUnsortedBlock(content);

  @override
  String apply(String content) {
    final lines = content.split('\n');
    final result = <String>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();
      if (_blockHeaders.contains(trimmed) && !line.startsWith(' ')) {
        result.add(line);
        i++;
        final entries = <_Entry>[];
        while (i < lines.length) {
          final inner = lines[i];
          if (inner.isEmpty) {
            break;
          }
          if (!inner.startsWith(_whitespace)) {
            break;
          }
          final entryLines = <String>[inner];
          var j = i + 1;
          while (j < lines.length) {
            final cont = lines[j];
            if (cont.isEmpty) {
              break;
            }
            final entryIndent = _leadingSpaces(inner);
            final contIndent = _leadingSpaces(cont);
            if (contIndent > entryIndent) {
              entryLines.add(cont);
              j++;
            } else {
              break;
            }
          }
          final keyMatch = _keyPattern.firstMatch(inner);
          if (keyMatch == null) {
            result.addAll(entryLines);
            i = j;
            continue;
          }
          entries.add(_Entry(name: keyMatch.group(1)!, lines: entryLines));
          i = j;
        }
        entries.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        for (final e in entries) {
          result.addAll(e.lines);
        }
      } else {
        result.add(line);
        i++;
      }
    }
    return result.join('\n');
  }

  bool _hasUnsortedBlock(String content) {
    final lines = content.split('\n');
    var i = 0;
    while (i < lines.length) {
      final trimmed = lines[i].trim();
      if (_blockHeaders.contains(trimmed) && !lines[i].startsWith(' ')) {
        i++;
        final names = <String>[];
        var firstIndent = -1;
        while (i < lines.length) {
          final inner = lines[i];
          if (inner.isEmpty) {
            break;
          }
          if (!inner.startsWith(_whitespace)) {
            break;
          }
          final indent = _leadingSpaces(inner);
          if (firstIndent < 0) {
            firstIndent = indent;
          }
          if (indent == firstIndent) {
            final keyMatch = _keyPattern.firstMatch(inner);
            if (keyMatch != null) {
              names.add(keyMatch.group(1)!);
            }
          }
          i++;
        }
        for (var k = 1; k < names.length; k++) {
          final cmp = names[k - 1].toLowerCase().compareTo(
            names[k].toLowerCase(),
          );
          if (cmp > 0) {
            return true;
          }
        }
      } else {
        i++;
      }
    }
    return false;
  }

  int _leadingSpaces(String line) {
    var n = 0;
    while (n < line.length && (line[n] == ' ' || line[n] == '\t')) {
      n++;
    }
    return n;
  }
}

class _Entry {
  _Entry({required this.name, required this.lines});
  final String name;
  final List<String> lines;
}
