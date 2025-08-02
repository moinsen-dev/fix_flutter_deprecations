import 'dart:io';

import 'package:fix_flutter_deprecations/src/command_runner.dart';
import 'package:fix_flutter_deprecations/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

class MockPubUpdater extends Mock implements PubUpdater {}

class MockProgress extends Mock implements Progress {}

class MockLogger extends Mock implements Logger {
  @override
  Level level = Level.info;

  void fixSummary({
    required int totalFiles,
    required int filesModified,
    required int filesWithErrors,
    required Duration elapsed,
  }) {
    super.noSuchMethod(
      Invocation.method(
        #fixSummary,
        [],
        {
          #totalFiles: totalFiles,
          #filesModified: filesModified,
          #filesWithErrors: filesWithErrors,
          #elapsed: elapsed,
        },
      ),
    );
  }

  void dryRunNotice() {
    super.noSuchMethod(Invocation.method(#dryRunNotice, []));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  group('FixFlutterDeprecationsCommandRunner - Integration', () {
    late MockLogger logger;
    late MockPubUpdater pubUpdater;
    late FixFlutterDeprecationsCommandRunner commandRunner;
    late Directory tempDir;
    late File dartFile;

    setUp(() async {
      logger = MockLogger();
      pubUpdater = MockPubUpdater();

      // Mock pub updater to avoid update checks
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      final progress = MockProgress();
      when(() => progress.complete(any())).thenReturn(null);
      when(() => progress.fail(any())).thenReturn(null);
      when(() => progress.update(any())).thenReturn(null);
      when(progress.cancel).thenReturn(null);

      when(() => logger.info(any())).thenReturn(null);
      when(() => logger.err(any())).thenReturn(null);
      when(() => logger.warn(any())).thenReturn(null);
      when(() => logger.success(any())).thenReturn(null);
      when(() => logger.detail(any())).thenReturn(null);
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => logger.dryRunNotice()).thenReturn(null);
      when(
        () => logger.fixSummary(
          totalFiles: any(named: 'totalFiles'),
          filesModified: any(named: 'filesModified'),
          filesWithErrors: any(named: 'filesWithErrors'),
          elapsed: any(named: 'elapsed'),
        ),
      ).thenAnswer((_) {});

      commandRunner = FixFlutterDeprecationsCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );

      tempDir = Directory.systemTemp.createTempSync('fix_deprecations_test_');
      dartFile = File(path.join(tempDir.path, 'test.dart'));
      await dartFile.writeAsString('''
import 'package:flutter/material.dart';

void main() {
  final color = Colors.red.withValues(alpha: 0.5);
}
''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('runs fix command by default with path argument', () async {
      final result = await commandRunner.run([tempDir.path]);
      expect(result, equals(ExitCode.success.code));

      // Verify the fix was applied
      final content = await dartFile.readAsString();
      expect(content, contains('withValues(alpha: 0.5)'));
    });

    test('--dry-run flag works', () async {
      final result = await commandRunner.run(['--dry-run', tempDir.path]);
      expect(result, equals(ExitCode.success.code));

      // Verify the file was not modified
      final content = await dartFile.readAsString();
      expect(content, contains('withOpacity(0.5)'));
      expect(content, isNot(contains('withValues')));

      // Verify dry run notice was shown
      verify(
        () => logger.warn(
          'Running in DRY RUN mode. No files will be modified.',
        ),
      ).called(1);
    });

    test('--backup flag creates backup files', () async {
      final result = await commandRunner.run(['--backup', tempDir.path]);
      expect(result, equals(ExitCode.success.code));

      // Verify backup file was created
      final backupFile = File('${dartFile.path}.backup');
      expect(backupFile.existsSync(), isTrue);
      expect(await backupFile.readAsString(), contains('withOpacity(0.5)'));

      // Verify original file was modified
      expect(await dartFile.readAsString(), contains('withValues(alpha: 0.5)'));
    });

    test('--list-rules flag lists rules', () async {
      final result = await commandRunner.run(['--list-rules']);
      expect(result, equals(ExitCode.success.code));

      // Verify rules were listed
      verify(
        () => logger.info(any(that: contains('withOpacity'))),
      ).called(greaterThanOrEqualTo(1));
      verify(
        () => logger.info(any(that: contains('surfaceContainerHighest'))),
      ).called(greaterThanOrEqualTo(1));
      verify(
        () => logger.info(any(that: contains('onSurface'))),
      ).called(greaterThanOrEqualTo(1));
    });

    test('--rules flag filters rules', () async {
      // Add a file with multiple deprecations
      final multiFile = File(path.join(tempDir.path, 'multi.dart'));
      await multiFile.writeAsString('''
import 'package:flutter/material.dart';

void main() {
  final color1 = Colors.red.withValues(alpha: 0.5);
  final color2 = Theme.of(context).colorScheme.background;
}
''');

      final result = await commandRunner.run([
        '--rules',
        'withOpacity',
        tempDir.path,
      ]);
      expect(result, equals(ExitCode.success.code));

      // Verify only withOpacity was fixed
      final content = await multiFile.readAsString();
      expect(content, contains('withValues(alpha: 0.5)'));
      expect(content, contains('background')); // Not fixed
    });

    test('--verbose flag shows detailed output', () async {
      final result = await commandRunner.run(['--verbose', tempDir.path]);
      expect(result, equals(ExitCode.success.code));

      // Verify verbose mode was enabled
      expect(logger.level, equals(Level.verbose));
    });

    test('no arguments shows help', () async {
      final result = await commandRunner.run([]);
      expect(result, equals(ExitCode.success.code));

      // Verify usage was shown (it's all in one info call)
      verify(
        () => logger.info(
          any(
            that: allOf(
              contains('Usage:'),
              contains('Options:'),
            ),
          ),
        ),
      ).called(1);
    });

    test('--version flag shows version', () async {
      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.success.code));

      // Verify version was shown
      verify(
        () => logger.info(any(that: matches(RegExp(r'\d+\.\d+\.\d+')))),
      ).called(1);
    });
  });
}
