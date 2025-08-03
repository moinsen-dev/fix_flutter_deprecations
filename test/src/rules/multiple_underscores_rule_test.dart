import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('MultipleUnderscoresRule', () {
    late MultipleUnderscoresRule rule;

    setUp(() {
      rule = const MultipleUnderscoresRule();
    });

    test('has correct properties', () {
      expect(rule.name, equals('multipleUnderscores'));
      expect(
        rule.description,
        equals('Replace multiple leading underscores with a single underscore'),
      );
      expect(rule.deprecatedPattern, equals('__+'));
      expect(rule.replacementExample, equals('_'));
    });

    group('matches', () {
      test('matches identifiers with multiple underscores', () {
        expect(rule.matches('String _privateVar = "test";'), isTrue);
        expect(rule.matches('void _method() {}'), isTrue);
        expect(rule.matches('class _MyClass {}'), isTrue);
        expect(rule.matches('final _field;'), isTrue);
      });

      test('matches constructor parameters with multiple underscores', () {
        expect(rule.matches('MyClass(this._field)'), isTrue);
        expect(rule.matches('MyClass({this._value})'), isTrue);
      });

      test('matches named parameters with multiple underscores', () {
        expect(rule.matches('void method({String _param})'), isTrue);
        expect(rule.matches('function({_name: "default"})'), isTrue);
      });

      test('does not match single underscore', () {
        expect(rule.matches('String _privateVar = "test";'), isFalse);
        expect(rule.matches('void _method() {}'), isFalse);
        expect(rule.matches('this._field'), isFalse);
      });

      test('does not match underscores in the middle', () {
        expect(rule.matches('some_snake_case'), isFalse);
        expect(rule.matches('CONSTANT_VALUE'), isFalse);
      });
    });

    group('apply', () {
      test('replaces multiple underscores in variable declarations', () {
        const input = 'String _privateVar = "test";';
        const expected = 'String _privateVar = "test";';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces triple underscores', () {
        const input = 'void _method() { return; }';
        const expected = 'void _method() { return; }';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces in multiple locations', () {
        const input = '''
class MyClass {
  String _field1;
  int _field2;
  
  MyClass(this._field1, this._field2);
  
  void _method() {
    var _local = 42;
  }
}''';
        const expected = '''
class MyClass {
  String _field1;
  int _field2;
  
  MyClass(this._field1, this._field2);
  
  void _method() {
    var _local = 42;
  }
}''';
        expect(rule.apply(input), equals(expected));
      });

      test('replaces in named parameters', () {
        const input = '''
void function({
  String _param1,
  int _param2 = 0,
}) {}''';
        const expected = '''
void function({
  String _param1,
  int _param2 = 0,
}) {}''';
        expect(rule.apply(input), equals(expected));
      });

      test('preserves generated code markers', () {
        const input = r'''
class __$GENERATED_Code {}
var __AUTO_generated = true;
final ___MOCK_object = Mock();''';
        expect(rule.apply(input), equals(input));
      });

      test('preserves test mock patterns', () {
        const input = r'class __$MockedClass extends Mock {}';
        expect(rule.apply(input), equals(input));
      });

      test('handles mixed cases', () {
        const input = '''
class Example {
  String _singleUnderscore;  // Should not change
  String _doubleUnderscore; // Should change to _
  String _tripleUnderscore; // Should change to _
  
  void _method1() {} // Should not change
  void _method2() {} // Should change to _
}''';
        const expected = '''
class Example {
  String _singleUnderscore;  // Should not change
  String _doubleUnderscore; // Should change to _
  String _tripleUnderscore; // Should change to _
  
  void _method1() {} // Should not change
  void _method2() {} // Should change to _
}''';
        expect(rule.apply(input), equals(expected));
      });

      test('returns unchanged if no matches', () {
        const input = '''
class Example {
  String _field;
  void _method() {}
}''';
        expect(rule.apply(input), equals(input));
      });
    });

    group('validate', () {
      test('validates successful transformation', () {
        const original = 'String _variable = "test";';
        const modified = 'String _variable = "test";';
        expect(rule.validate(original, modified), isTrue);
      });

      test('validates when no changes needed', () {
        const original = 'String _variable = "test";';
        const modified = 'String _variable = "test";';
        expect(rule.validate(original, modified), isTrue);
      });

      test('fails validation if content deleted', () {
        const original = 'String _variable = "test";';
        const modified = '';
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if brackets become unbalanced', () {
        const original = 'void _method() { return; }';
        const modified = 'void _method() { return;'; // Missing closing brace
        expect(rule.validate(original, modified), isFalse);
      });

      test('fails validation if multiple underscores remain', () {
        const original = 'String _variable = "test";';
        const modified = 'String _variable = "test";'; // Not fixed
        expect(rule.validate(original, modified), isFalse);
      });

      test('passes validation when preserved patterns remain', () {
        const original = r'class __$MockClass { String _field; }';
        const modified = r'class __$MockClass { String _field; }';
        expect(rule.validate(original, modified), isTrue);
      });
    });
  });
}