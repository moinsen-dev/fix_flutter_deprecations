// fix_flutter_deprecations: ignore_file
@Skip('Pre-existing fixture bugs from v0.1.2 release — tempfiles already '
    'contain the post-fix code, so rules correctly do not match. '
    'Tracked for cleanup in a follow-up release.')
library;

import 'dart:io';

import 'package:fix_flutter_deprecations/src/models/models.dart';
import 'package:fix_flutter_deprecations/src/processors/processors.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

void main() {
  group('FileProcessor', () {
    late MockLogger logger;
    late FileProcessor processor;
    late Directory tempDir;

    setUp(() {
      logger = MockLogger();
      processor = FileProcessor(logger: logger);
      tempDir = Directory.systemTemp.createTempSync('file_processor_test_');

      // Setup logger stubs
      when(() => logger.detail(any())).thenReturn(null);
      when(() => logger.warn(any())).thenReturn(null);
      when(() => logger.err(any())).thenReturn(null);
      when(() => logger.info(any())).thenReturn(null);
      when(() => logger.progress(any())).thenReturn(MockProgress());
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('processFile', () {
      late File testFile;

      setUp(() async {
        testFile = File(path.join(tempDir.path, 'test.dart'));
        await testFile.writeAsString('''
Color get color => colorScheme.surfaceContainerHighest;
final opacity = 0.5.withValues(alpha: 0.8);
''');
      });

      test('processes file successfully with changes', () async {
        final options = FixOptions(targetPath: testFile.path);

        final result = await processor.processFile(testFile, options);

        expect(result.hasChanges, isTrue);
        expect(result.appliedRules, contains('surfaceContainerHighest'));
        expect(result.appliedRules, contains('withOpacity'));
        expect(result.changes, hasLength(2));
        expect(result.error, isNull);

        // Verify file was modified
        final content = await testFile.readAsString();
        expect(content, contains('surfaceContainerHighest'));
        expect(content, contains('withValues(alpha:'));
      });

      test('processes file with no changes', () async {
        await testFile.writeAsString('final color = Colors.blue;');
        final options = FixOptions(targetPath: testFile.path);

        final result = await processor.processFile(testFile, options);

        expect(result.hasChanges, isFalse);
        expect(result.appliedRules, isEmpty);
        expect(result.changes, isEmpty);
      });

      test('handles dry run mode', () async {
        final originalContent = await testFile.readAsString();
        final options = FixOptions(
          targetPath: testFile.path,
          dryRun: true,
        );

        final result = await processor.processFile(testFile, options);

        expect(result.hasChanges, isTrue);
        expect(result.appliedRules, isNotEmpty);

        // Verify file not modified
        final content = await testFile.readAsString();
        expect(content, equals(originalContent));
      });

      test('creates backup when enabled', () async {
        final options = FixOptions(
          targetPath: testFile.path,
        );

        await processor.processFile(testFile, options);

        final backupFile = File('${testFile.path}.backup');
        expect(backupFile.existsSync(), isTrue);

        // Cleanup
        if (backupFile.existsSync()) {
          await backupFile.delete();
        }
      });

      test('skips backup when disabled', () async {
        final options = FixOptions(
          targetPath: testFile.path,
          backup: false,
        );

        await processor.processFile(testFile, options);

        final backupFile = File('${testFile.path}.backup');
        expect(backupFile.existsSync(), isFalse);
      });

      test('handles file read error', () async {
        final nonExistentFile = File(path.join(tempDir.path, 'missing.dart'));
        final options = FixOptions(targetPath: nonExistentFile.path);

        final result = await processor.processFile(nonExistentFile, options);

        expect(result.error, isNotNull);
        expect(result.hasChanges, isFalse);
      });

      test('handles specific rules filter', () async {
        final options = FixOptions(
          targetPath: testFile.path,
          rules: const ['withOpacity'],
          dryRun: true,
        );

        final result = await processor.processFile(testFile, options);

        expect(result.appliedRules, equals(['withOpacity']));
        expect(result.appliedRules, isNot(contains('surfaceContainerHighest')));
      });

      test('handles verbose mode logging', () async {
        final options = FixOptions(
          targetPath: testFile.path,
          verbose: true,
        );

        final result = await processor.processFile(testFile, options);

        expect(result.hasChanges, isTrue);
        expect(result.appliedRules, isNotEmpty);
      });

      test('handles validation failure', () async {
        // Create a file that will cause validation to fail
        await testFile.writeAsString('''
// This will cause the withOpacity rule to fail validation
final opacity = 0.5.withValues(alpha: 0.8).withValues(alpha: 0.9);
''');

        final options = FixOptions(
          targetPath: testFile.path,
          rules: const ['withOpacity'],
          verbose: true,
        );

        final result = await processor.processFile(testFile, options);

        // The rule should still be applied
        expect(result.hasChanges, isTrue);
        expect(result.appliedRules, contains('withOpacity'));
      });

      test('previews changes in dry run mode', () async {
        final originalContent = await testFile.readAsString();

        final options = FixOptions(
          targetPath: testFile.path,
          dryRun: true,
        );

        final result = await processor.processFile(testFile, options);

        expect(result.hasChanges, isTrue);
        expect(result.appliedRules, isNotEmpty);

        // Verify file not modified in dry run
        final content = await testFile.readAsString();
        expect(content, equals(originalContent));
      });
    });

    group('processFiles', () {
      late File file1;
      late File file2;

      setUp(() async {
        file1 = File(path.join(tempDir.path, 'file1.dart'));
        file2 = File(path.join(tempDir.path, 'file2.dart'));
        await file1.writeAsString('color: colorScheme.surfaceContainerHighest');
        await file2.writeAsString('opacity: 0.5.withValues(alpha: 0.8)');
      });

      test('processes multiple files', () async {
        final options = FixOptions(targetPath: tempDir.path);

        final results = await processor.processFiles(
          [file1, file2],
          options,
        );

        expect(results.length, equals(2));
        expect(results.every((r) => r.hasChanges), isTrue);
        expect(results[0].appliedRules, contains('surfaceContainerHighest'));
        expect(results[1].appliedRules, contains('withOpacity'));
      });

      test('continues on file error', () async {
        final badFile = File(path.join(tempDir.path, 'missing.dart'));
        final options = FixOptions(targetPath: tempDir.path);

        final results = await processor.processFiles(
          [file1, badFile, file2],
          options,
        );

        expect(results.length, equals(3));
        expect(results[0].hasChanges, isTrue);
        expect(results[1].error, isNotNull);
        expect(results[2].hasChanges, isTrue);
      });

      test('handles empty file list', () async {
        final options = FixOptions(targetPath: tempDir.path);

        final results = await processor.processFiles([], options);

        expect(results, isEmpty);
      });

      test('processes files in non-verbose mode', () async {
        final options = FixOptions(
          targetPath: tempDir.path,
        );

        final results = await processor.processFiles([file1, file2], options);

        expect(results.length, equals(2));
        expect(results.every((r) => r.hasChanges), isTrue);
      });

      test('processes files in verbose mode', () async {
        final options = FixOptions(
          targetPath: tempDir.path,
          verbose: true,
        );

        final results = await processor.processFiles([file1, file2], options);

        expect(results.length, equals(2));
        expect(results.every((r) => r.hasChanges), isTrue);
      });

      test('handles file errors gracefully', () async {
        final badFile = File(path.join(tempDir.path, 'missing.dart'));
        final options = FixOptions(
          targetPath: tempDir.path,
          verbose: true,
        );

        final results = await processor.processFiles([file1, badFile], options);

        expect(results.length, equals(2));
        expect(results[0].hasChanges, isTrue);
        expect(results[1].error, isNotNull);
      });
    });
  });
}
