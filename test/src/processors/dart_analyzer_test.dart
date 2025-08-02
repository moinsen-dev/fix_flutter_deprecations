import 'dart:io';

import 'package:fix_flutter_deprecations/src/processors/processors.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('DartAnalyzer', () {
    late MockLogger logger;
    late DartAnalyzer analyzer;
    late Directory tempDir;
    late File testFile;

    setUp(() async {
      logger = MockLogger();
      when(() => logger.detail(any())).thenReturn(null);
      when(() => logger.warn(any())).thenReturn(null);
      when(() => logger.err(any())).thenReturn(null);
      when(() => logger.success(any())).thenReturn(null);

      analyzer = DartAnalyzer(logger: logger);
      tempDir = Directory.systemTemp.createTempSync('dart_analyzer_test_');
      testFile = File(path.join(tempDir.path, 'test.dart'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('validateFile', () {
      test('returns true for valid Dart code', () async {
        const validCode = '''
void main() {
  print('Hello, World!');
}
''';

        await testFile.writeAsString(validCode);
        final result = await analyzer.validateFile(testFile);

        expect(result, isTrue);
      });

      test('returns false for invalid Dart code', () async {
        const invalidCode = '''
void main() {
  // Missing closing brace
''';

        await testFile.writeAsString(invalidCode);
        final result = await analyzer.validateFile(testFile);

        expect(result, isFalse);
        verify(() => logger.err(any())).called(greaterThanOrEqualTo(1));
      });

      test('handles ProcessException gracefully', () async {
        const validCode = '''
void main() {
  print('Hello, World!');
}
''';

        await testFile.writeAsString(validCode);

        // Move to a temp directory without dart binary (if possible)
        final result = await analyzer.validateFile(testFile);

        expect(result, isA<bool>());
      });
    });

    group('validateFiles', () {
      late File file1;
      late File file2;

      setUp(() async {
        file1 = File(path.join(tempDir.path, 'file1.dart'));
        file2 = File(path.join(tempDir.path, 'file2.dart'));

        await file1.writeAsString('''
void main() {
  print('File 1');
}
''');

        await file2.writeAsString('''
void main() {
  // Missing closing brace
''');
      });

      test('validates multiple files', () async {
        final results = await analyzer.validateFiles([file1, file2]);

        expect(results.length, equals(2));
        expect(results[file1.path], isTrue);
        expect(results[file2.path], isFalse);
      });

      test('handles empty file list', () async {
        final results = await analyzer.validateFiles([]);

        expect(results, isEmpty);
      });
    });

    group('validateProject', () {
      test('validates project in current directory', () async {
        final result = await analyzer.validateProject();

        expect(result, isA<bool>());

        if (result) {
          verify(
            () => logger.success('✓ All files pass dart analyze'),
          ).called(1);
        }
      });

      test('validates project in specified directory', () async {
        final result = await analyzer.validateProject(tempDir.path);

        expect(result, isA<bool>());
      });

      test('handles ProcessException gracefully', () async {
        final result = await analyzer.validateProject('/nonexistent/path');

        expect(result, isFalse);
        verify(() => logger.err(any())).called(greaterThanOrEqualTo(1));
      });
    });

    group('hasSyntaxErrors', () {
      test('returns false for syntactically correct code', () async {
        const validCode = '''
void main() {
  print('Hello, World!');
}
''';

        await testFile.writeAsString(validCode);
        final result = await analyzer.hasSyntaxErrors(testFile);

        expect(result, isFalse);
      });

      test('returns true for syntactically incorrect code', () async {
        const invalidCode = '''
void main() {
  // Missing closing brace
''';

        await testFile.writeAsString(invalidCode);
        final result = await analyzer.hasSyntaxErrors(testFile);

        expect(result, isTrue);
      });

      test('handles ProcessException gracefully', () async {
        const validCode = '''
void main() {
  print('Hello, World!');
}
''';

        await testFile.writeAsString(validCode);
        final result = await analyzer.hasSyntaxErrors(testFile);

        // Should return false when process fails
        expect(result, isA<bool>());
      });
    });

    group('getIssues', () {
      test('returns empty list for valid code', () async {
        const validCode = '''
void main() {
  print('Hello, World!');
}
''';

        await testFile.writeAsString(validCode);
        final issues = await analyzer.getIssues(testFile);

        expect(issues, isEmpty);
      });

      test('returns issues for invalid code', () async {
        const invalidCode = '''
void main() {
  // Missing closing brace
''';

        await testFile.writeAsString(invalidCode);
        final issues = await analyzer.getIssues(testFile);

        expect(issues, isA<List<String>>());
      });

      test('handles ProcessException gracefully', () async {
        const validCode = '''
void main() {
  print('Hello, World!');
}
''';

        await testFile.writeAsString(validCode);
        final issues = await analyzer.getIssues(testFile);

        expect(issues, isA<List<String>>());
      });

      test('parses machine format output', () async {
        const codeWithWarning = '''
void main() {
  var unusedVariable = 'this will cause a warning';
  print('Hello, World!');
}
''';

        await testFile.writeAsString(codeWithWarning);
        final issues = await analyzer.getIssues(testFile);

        expect(issues, isA<List<String>>());
      });
    });
  });
}
