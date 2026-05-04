import 'package:fix_flutter_deprecations/src/rules/deprecation_rule.dart';

/// Fixes `cascade_invocations`: collapses runs of statements that call
/// methods on the same receiver into a cascade chain.
///
/// Example:
/// ```dart
/// buf.writeln('a');
/// buf.writeln('b');
/// buf.writeln('c');
/// ```
/// becomes:
/// ```dart
/// buf
///   ..writeln('a')
///   ..writeln('b')
///   ..writeln('c');
/// ```
///
/// Conservative — only triggers when **two or more** consecutive lines:
/// - have identical leading whitespace
/// - call a method/setter on the same receiver
/// - end with a single trailing `;`
/// - contain no `await`, `return`, or assignment from the call
class CascadeInvocationsRule extends DeprecationRule {
  /// Creates a new [CascadeInvocationsRule].
  const CascadeInvocationsRule();

  @override
  String get name => 'cascadeInvocations';

  @override
  String get description =>
      'Combine consecutive method calls on the same receiver into a cascade';

  @override
  String get deprecatedPattern => 'foo.a(); foo.b();';

  @override
  String get replacementExample => 'foo..a()..b();';

  /// Matches a single statement line: `<indent><receiver>.<rest>;`
  /// Receiver must be a simple identifier (no chained calls, no this/super).
  static final _stmtLine = RegExp(
    r'^([ \t]*)([A-Za-z_]\w*)\.(\S.*);[ \t]*$',
  );

  @override
  bool matches(String content) {
    return _findRuns(content).isNotEmpty;
  }

  @override
  String apply(String content) {
    final runs = _findRuns(content);
    if (runs.isEmpty) {
      return content;
    }
    final lines = content.split('\n');
    // Replace bottom-up to keep indices valid.
    for (final run in runs.reversed) {
      final receiver = run.receiver;
      final indent = run.indent;
      final calls = <String>[];
      for (var i = run.start; i <= run.end; i++) {
        final m = _stmtLine.firstMatch(lines[i])!;
        calls.add(m.group(3)!);
      }
      final replacement = <String>[
        '$indent$receiver',
        for (var i = 0; i < calls.length; i++)
          '$indent  ..${calls[i]}${i == calls.length - 1 ? ';' : ''}',
      ];
      lines.replaceRange(run.start, run.end + 1, replacement);
    }
    return lines.join('\n');
  }

  List<_Run> _findRuns(String content) {
    final lines = content.split('\n');
    final runs = <_Run>[];
    var i = 0;
    while (i < lines.length) {
      final m = _stmtLine.firstMatch(lines[i]);
      if (m == null) {
        i++;
        continue;
      }
      final indent = m.group(1)!;
      final receiver = m.group(2)!;
      if (_isReservedReceiver(receiver) || _looksLikeClassName(receiver)) {
        i++;
        continue;
      }
      var j = i + 1;
      while (j < lines.length) {
        final n = _stmtLine.firstMatch(lines[j]);
        if (n == null) {
          break;
        }
        if (n.group(1)! != indent) {
          break;
        }
        if (n.group(2)! != receiver) {
          break;
        }
        if (_containsForbiddenToken(n.group(3)!)) {
          break;
        }
        j++;
      }
      if (_containsForbiddenToken(m.group(3)!)) {
        i++;
        continue;
      }
      if (j - i >= 2) {
        runs.add(
          _Run(
            start: i,
            end: j - 1,
            indent: indent,
            receiver: receiver,
          ),
        );
        i = j;
      } else {
        i++;
      }
    }
    return runs;
  }

  /// Names starting with an uppercase letter are almost always classes —
  /// cascading static calls on them would produce invalid Dart.
  bool _looksLikeClassName(String name) {
    if (name.isEmpty) {
      return false;
    }
    final first = name[0];
    return first == first.toUpperCase() && first != first.toLowerCase();
  }

  /// Receivers we never cascade — these are usually keywords, not vars.
  bool _isReservedReceiver(String name) {
    return const {
      'return',
      'await',
      'final',
      'var',
      'const',
      'if',
      'for',
      'while',
      'switch',
      'this',
      'super',
      'assert',
      'throw',
      'yield',
    }.contains(name);
  }

  /// Tokens that disqualify a statement from being part of a cascade run.
  bool _containsForbiddenToken(String body) {
    if (body.contains('=')) {
      // Allow `==`, `!=`, `<=`, `>=`, `=>` inside arguments — only reject
      // top-level assignment which we approximate by leading "= " before any
      // paren.
      final parenStart = body.indexOf('(');
      final headEnd = parenStart < 0 ? body.length : parenStart;
      final head = body.substring(0, headEnd);
      if (head.contains('=')) {
        return true;
      }
    }
    return false;
  }
}

class _Run {
  _Run({
    required this.start,
    required this.end,
    required this.indent,
    required this.receiver,
  });

  final int start;
  final int end;
  final String indent;
  final String receiver;
}
