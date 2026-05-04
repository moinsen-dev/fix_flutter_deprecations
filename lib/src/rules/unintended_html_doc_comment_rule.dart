import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Fixes `unintended_html_in_doc_comment`: wraps `<Type>` style snippets
/// inside `///` doc comments in backticks so the analyzer doesn't treat
/// them as HTML.
///
/// Allowed HTML tags (`br`, `p`, `a`, `code`, `pre`, …) are left alone.
class UnintendedHtmlDocCommentRule extends DeprecationRule {
  /// Creates a new [UnintendedHtmlDocCommentRule].
  const UnintendedHtmlDocCommentRule();

  @override
  String get name => 'unintendedHtmlDocComment';

  @override
  String get description =>
      'Wrap angle-bracket type fragments in doc comments with backticks';

  @override
  String get deprecatedPattern => 'angle-bracketed type in doc comment';

  @override
  String get replacementExample => 'backtick-wrapped type in doc comment';

  static const _allowedHtmlTags = {
    'br',
    'p',
    'a',
    'code',
    'pre',
    'b',
    'i',
    'em',
    'strong',
    'ul',
    'ol',
    'li',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
  };

  static final _angleType = RegExp(r'<([A-Z][\w<>, ?]*)>');
  static final _docLine = RegExp(r'^\s*///');

  @override
  bool matches(String content) {
    for (final line in content.split('\n')) {
      if (!_docLine.hasMatch(line)) {
        continue;
      }
      if (_findUnwrappedAngles(line).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  @override
  String apply(String content) {
    final lines = content.split('\n');
    var changed = false;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!_docLine.hasMatch(line)) {
        continue;
      }
      final ranges = _findUnwrappedAngles(line);
      if (ranges.isEmpty) {
        continue;
      }
      lines[i] = _applyRanges(line, ranges);
      changed = true;
    }
    return changed ? lines.join('\n') : content;
  }

  List<(int, int)> _findUnwrappedAngles(String line) {
    final ranges = <(int, int)>[];
    for (final match in _angleType.allMatches(line)) {
      final inner = match.group(1)!;
      final firstWord = inner.split(RegExp('[ <,]')).first.toLowerCase();
      if (_allowedHtmlTags.contains(firstWord)) {
        continue;
      }
      if (_isInsideBackticks(line, match.start)) {
        continue;
      }
      ranges.add((match.start, match.end));
    }
    return ranges;
  }

  bool _isInsideBackticks(String line, int index) {
    var ticks = 0;
    for (var i = 0; i < index; i++) {
      if (line[i] == '`') {
        ticks++;
      }
    }
    return ticks.isOdd;
  }

  String _applyRanges(String line, List<(int, int)> ranges) {
    final buffer = StringBuffer();
    var cursor = 0;
    for (final (start, end) in ranges) {
      buffer
        ..write(line.substring(cursor, start))
        ..write('`')
        ..write(line.substring(start, end))
        ..write('`');
      cursor = end;
    }
    buffer.write(line.substring(cursor));
    return buffer.toString();
  }
}
