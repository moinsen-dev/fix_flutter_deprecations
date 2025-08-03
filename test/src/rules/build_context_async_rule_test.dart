import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('BuildContextAsyncRule', () {
    late BuildContextAsyncRule rule;

    setUp(() {
      rule = const BuildContextAsyncRule();
    });

    test('has correct properties', () {
      expect(rule.name, equals('buildContextAsync'));
      expect(
        rule.description,
        equals('Add mounted checks for BuildContext usage after async gaps'),
      );
      expect(rule.deprecatedPattern, equals('BuildContext after await'));
      expect(
        rule.replacementExample,
        equals('if (mounted) { /* use context */ }'),
      );
    });

    group('matches', () {
      test('matches Navigator usage after await', () {
        const code = '''
void _handleTap() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.of(context).pop();
  }
}''';
        expect(rule.matches(code), isTrue);
      });

      test('matches showDialog after await', () {
        const code = '''
void _showDelayedDialog() async {
  await _loadData();
  if (mounted) {
    showDialog(
    context: context,
    builder: (context) => AlertDialog(),
  );
  }
}''';
        expect(rule.matches(code), isTrue);
      });

      test('matches ScaffoldMessenger after await', () {
        const code = '''
void _showMessage() async {
  await _saveData();
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Saved')),
  );
  }
}''';
        expect(rule.matches(code), isTrue);
      });

      test('matches Theme.of after await', () {
        const code = '''
void _updateTheme() async {
  await _loadSettings();
  final theme = Theme.of(context);
}''';
        expect(rule.matches(code), isTrue);
      });

      test('does not match when mounted check exists', () {
        const code = '''
void _handleTap() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.of(context).pop();
  }
}''';
        expect(rule.matches(code), isFalse);
      });

      test('does not match without await', () {
        const code = '''
void _handleTap() {
  Navigator.of(context).pop();
}''';
        expect(rule.matches(code), isFalse);
      });
    });

    group('apply', () {
      test('adds mounted check for Navigator in StatefulWidget', () {
        const input = '''
class MyWidget extends State<MyScreen> {
  void _handleTap() async {
    await Future.delayed(Duration(seconds: 1));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}''';
        const expected = '''
class MyWidget extends State<MyScreen> {
  void _handleTap() async {
    await Future.delayed(Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}''';
        expect(rule.apply(input), equals(expected));
      });

      test('adds context.mounted check in build method', () {
        const input = '''
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: () async {
      await _loadData();
      if (mounted) {
        Navigator.of(context).pop();
      }
    },
    child: Text('Load'),
  );
}''';
        const expected = '''
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: () async {
      await _loadData();

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    },
    child: Text('Load'),
  );
}''';
        expect(rule.apply(input), equals(expected));
      });

      test('adds mounted check for showDialog', () {
        const input = '''
class MyWidget extends State<MyScreen> {
  void _showDelayedDialog() async {
    await _loadData();
    if (mounted) {
      showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
      ),
    );
    }
  }
}''';
        const expected = '''
class MyWidget extends State<MyScreen> {
  void _showDelayedDialog() async {
    await _loadData();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Success'),
        ),
      );
    }
  }
}''';
        expect(rule.apply(input), equals(expected));
      });

      test('adds mounted check for ScaffoldMessenger', () {
        const input = '''
void _showMessage() async {
  await _saveData();
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Saved')),
  );
  }
}''';
        const expected = '''
void _showMessage() async {
  await _saveData();

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved')),
    );
  }
}''';
        expect(rule.apply(input), equals(expected));
      });

      test('handles multiple async gaps', () {
        const input = '''
class MyWidget extends State<MyScreen> {
  void _complexFlow() async {
    await _step1();
    if (mounted) {
      Navigator.of(context).push(route1);
    }

    await _step2();
    if (mounted) {
      showDialog(context: context, builder: (_) => Dialog());
    }
  }
}''';
        const expected = '''
class MyWidget extends State<MyScreen> {
  void _complexFlow() async {
    await _step1();

    if (mounted) {
      Navigator.of(context).push(route1);
    }

    await _step2();

    if (mounted) {
      showDialog(context: context, builder: (_) => Dialog());
    }
  }
}''';
        expect(rule.apply(input), equals(expected));
      });

      test('preserves existing mounted checks', () {
        const input = '''
void _handleTap() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.of(context).pop();
  }
}''';
        expect(rule.apply(input), equals(input));
      });

      test('handles custom context parameter name', () {
        const input = '''
void _buildContent(BuildContext ctx) async {
  await _loadData();
  Navigator.of(ctx).pop();
}''';
        const expected = '''
void _buildContent(BuildContext ctx) async {
  await _loadData();

  if (ctx.mounted) {
    Navigator.of(ctx).pop();
  }
}''';
        expect(rule.apply(input), equals(expected));
      });

      test('maintains proper indentation', () {
        const input = '''
class MyWidget extends State<MyScreen> {
  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      await _submitForm();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}''';
        const expected = '''
class MyWidget extends State<MyScreen> {
  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      await _submitForm();

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}''';
        expect(rule.apply(input), equals(expected));
      });

      test('returns unchanged if no matches', () {
        const input = '''
void _handleTap() {
  Navigator.of(context).pop();
}''';
        expect(rule.apply(input), equals(input));
      });
    });

    group('validate', () {
      test('validates successful transformation', () {
        const original = '''
void _handleTap() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.of(context).pop();
  }
}''';
        const modified = '''
void _handleTap() async {
  await Future.delayed(Duration(seconds: 1));

  if (context.mounted) {
    Navigator.of(context).pop();
  }
}''';
        expect(rule.validate(original, modified), isTrue);
      });

      test('validates when no changes needed', () {
        const original = '''
void _handleTap() {
  Navigator.of(context).pop();
}''';
        const modified = '''
void _handleTap() {
  Navigator.of(context).pop();
}''';
        expect(rule.validate(original, modified), isTrue);
      });

      test('fails validation if content deleted', () {
        const original = '''
void _handleTap() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.of(context).pop();
  }
}''';
        const modified = '';
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if brackets become unbalanced', () {
        const original = '''
void _handleTap() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.of(context).pop();
  }
}''';
        const modified = '''
void _handleTap() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.of(context).pop();
  // Missing closing brace
}''';
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if pattern still exists', () {
        const original = '''
void _handleTap() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.of(context).pop();
  }
}''';
        const modified = '''
void _handleTap() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.of(context).pop();
  }
}''';
        expect(rule.validate(original, modified), isFalse);
      });
    });
  });
}
