// This is just a tool to calculate the code coverage.
// ignore_for_file: avoid_print

/// Example Flutter file with deprecated APIs that need fixing
void main() {
  print('Example file showing deprecated Flutter APIs:');
  print('');
  print('Before running fix_deprecations:');
  print('----------------------------------------');

  // Show the original deprecated code
  const deprecatedCode = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Deprecated: withOpacity
    final color1 = Colors.blue.withValues(alpha: 0.5);
    final color2 = Theme.of(context).primaryColor.withValues(alpha: 0.8);

    // Deprecated: surfaceContainerHighest
    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    // Deprecated: onSurface
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      color: color1,
      child: Text(
        'Hello World',
        style: TextStyle(color: textColor),
      ),
    );
  }
}
''';

  print(deprecatedCode);
  print('');
  print('After running fix_deprecations:');
  print('----------------------------------------');

  // Show the fixed code
  const fixedCode = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Fixed: withOpacity → withValues
    final color1 = Colors.blue.withValues(alpha: 0.5);
    final color2 = Theme.of(context).primaryColor.withValues(alpha: 0.8);

    // Fixed: surfaceContainerHighest → surfaceContainerHighest
    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    // Fixed: onSurface → onSurface
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      color: color1,
      child: Text(
        'Hello World',
        style: TextStyle(color: textColor),
      ),
    );
  }
}
''';

  print(fixedCode);
  print('');
  print('To fix these deprecations in your project, run:');
  print('  fix_deprecations');
  print('');
  print('Or preview changes first with:');
  print('  fix_deprecations --dry-run');
}
