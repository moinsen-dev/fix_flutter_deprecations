import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('PopScopeRule', () {
    late PopScopeRule rule;

    setUp(() {
      rule = const PopScopeRule();
    });

    test('has correct properties', () {
      expect(rule.name, equals('willPopScope'));
      expect(
        rule.description,
        equals(
          'Replace deprecated PopScope with PopScope for predictive '
          'back support',
        ),
      );
      expect(rule.deprecatedPattern, equals('PopScope'));
      expect(rule.replacementExample, equals('PopScope'));
    });

    group('matches', () {
      test('matches PopScope widget', () {
        expect(rule.matches('PopScope('), isTrue);
        expect(rule.matches('return PopScope('), isTrue);
        expect(
          rule.matches('''
          PopScope(
            canPop: false,
            child: Scaffold(),
          )
          '''),
          isTrue,
        );
      });

      test('matches PopScope with spaces', () {
        expect(rule.matches('PopScope ('), isTrue);
        expect(rule.matches('PopScope\n('), isTrue);
      });

      test('does not match PopScope', () {
        expect(rule.matches('PopScope('), isFalse);
        expect(rule.matches('willPopScope'), isFalse);
        expect(rule.matches('WillPop'), isFalse);
      });
    });

    group('apply', () {
      test('replaces simple PopScope with constant true', () {
        const input = '''
PopScope(
  canPop: true,
  child: Container(),
)''';
        const expected = '''
PopScope(
  canPop: true,
  child: Container(),
)''';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces simple PopScope with constant false', () {
        const input = '''
PopScope(
  canPop: false,
  child: Container(),
)''';
        const expected = '''
PopScope(
  canPop: false,
  child: Container(),
)''';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces PopScope with simple return block', () {
        const input = '''
PopScope(
  canPop: true,
  child: Container(),
)''';
        const expected = '''
PopScope(
  canPop: true,
  child: Container(),
)''';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces PopScope with complex logic', () {
        const input = '''
PopScope(
  canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
        ],
      ),
    );
        if (shouldPop ?? false) {
          navigator.pop();
        }
      },
  child: Scaffold(),
)''';

        const expected = '''
PopScope(
  canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
        ],
      ),
    );
        if (shouldPop ?? false) {
          navigator.pop();
        }
      },
  child: Scaffold(),
)''';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces PopScope with variable expression', () {
        const input = '''
PopScope(
  canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        final bool shouldPop = await (canExit);
        if (shouldPop) {
          navigator.pop();
        }
      },
  child: Container(),
)''';
        const expected = '''
PopScope(
  canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        final bool shouldPop = await (canExit);
        if (shouldPop) {
          navigator.pop();
        }
      },
  child: Container(),
)''';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces multiple PopScope instances', () {
        const input = '''
Column(
  children: [
    PopScope(
      canPop: true,
      child: Container(),
    ),
    PopScope(
      canPop: false,
      child: Text('Test'),
    ),
  ],
)''';
        const expected = '''
Column(
  children: [
    PopScope(
      canPop: true,
      child: Container(),
    ),
    PopScope(
      canPop: false,
      child: Text('Test'),
    ),
  ],
)''';
        expect(rule.apply(input), equals(expected));
      });

      test('returns unchanged if no matches', () {
        const input = 'PopScope(canPop: true, child: Container())';
        expect(rule.apply(input), equals(input));
      });
    });

    group('validate', () {
      test('validates successful transformation', () {
        const original =
            'PopScope(canPop: true, child: Container())';
        const modified = 'PopScope(canPop: true, child: Container())';
        expect(rule.validate(original, modified), isTrue);
      });

      test('validates when no changes needed', () {
        const original = 'PopScope(canPop: true, child: Container())';
        const modified = 'PopScope(canPop: true, child: Container())';
        expect(rule.validate(original, modified), isTrue);
      });

      test('fails validation if content deleted', () {
        const original =
            'PopScope(canPop: true, child: Container())';
        const modified = '';
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if PopScope remains', () {
        const original =
            'PopScope(canPop: true, child: Container())';
        const modified =
            'PopScope(canPop: true, child: Container())';
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if PopScope not added', () {
        const original =
            'PopScope(canPop: true, child: Container())';
        const modified = 'Container()';
        expect(rule.validate(original, modified), isFalse);
      });
    });
  });
}