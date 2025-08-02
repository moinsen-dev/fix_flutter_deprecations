import 'package:fix_flutter_deprecations/src/utils/utils.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

void main() {
  group('LoggerExtensions', () {
    late MockLogger logger;

    setUp(() {
      logger = MockLogger();

      // Setup default stubs
      when(() => logger.detail(any())).thenReturn(null);
      when(() => logger.success(any())).thenReturn(null);
      when(() => logger.err(any())).thenReturn(null);
      when(() => logger.info(any())).thenReturn(null);
      when(() => logger.warn(any())).thenReturn(null);
    });

    group('fileStart', () {
      test('logs file processing start', () {
        logger.fileStart('/test/file.dart');

        verify(() => logger.detail('Processing: /test/file.dart')).called(1);
      });
    });

    group('fileComplete', () {
      test('logs success when file has changes', () {
        logger.fileComplete('/test/file.dart', hasChanges: true);

        verify(() => logger.success('✓ Fixed: /test/file.dart')).called(1);
      });

      test('logs detail when file has no changes', () {
        logger.fileComplete('/test/file.dart', hasChanges: false);

        verify(() => logger.detail('✓ No changes: /test/file.dart')).called(1);
      });
    });

    group('fileError', () {
      test('logs file error', () {
        logger.fileError('/test/file.dart', 'Permission denied');

        verify(
          () => logger.err('✗ Error in /test/file.dart: Permission denied'),
        ).called(1);
      });
    });

    group('ruleApplied', () {
      test('logs rule application', () {
        logger.ruleApplied('withOpacity', '/test/file.dart');

        verify(
          () =>
              logger.detail('  Applied rule "withOpacity" to /test/file.dart'),
        ).called(1);
      });
    });

    group('fixSummary', () {
      test('logs fix summary', () {
        logger.fixSummary(
          totalFiles: 10,
          filesModified: 5,
          filesWithErrors: 0,
          elapsed: const Duration(seconds: 3),
        );

        verify(() => logger.info('')).called(2);
        verify(() => logger.info('Summary:')).called(1);
        verify(() => logger.info('  Total files scanned: 10')).called(1);
        verify(() => logger.info('  Files modified: 5')).called(1);
        verify(() => logger.info('  Time elapsed: 3s')).called(1);
      });

      test('logs warning for files with errors', () {
        logger.fixSummary(
          totalFiles: 10,
          filesModified: 5,
          filesWithErrors: 2,
          elapsed: const Duration(seconds: 3),
        );

        verify(() => logger.warn('  Files with errors: 2')).called(1);
      });
    });

    group('dryRunNotice', () {
      test('logs dry run warning and info', () {
        logger.dryRunNotice();

        verify(
          () => logger.warn(
            'Running in DRY RUN mode. No files will be modified.',
          ),
        ).called(1);
        verify(() => logger.info('')).called(1);
      });
    });

    group('backupCreated', () {
      test('logs backup creation', () {
        logger.backupCreated('/test/file.dart');

        verify(
          () => logger.detail('  Created backup: /test/file.dart.backup'),
        ).called(1);
      });
    });

    group('backupRestored', () {
      test('logs backup restoration', () {
        logger.backupRestored('/test/file.dart');

        verify(
          () => logger.warn('  Restored from backup: /test/file.dart'),
        ).called(1);
      });
    });

    group('progressBar', () {
      test('creates progress with message', () {
        final mockProgress = MockProgress();
        when(() => logger.progress(any())).thenReturn(mockProgress);

        final progress = logger.progressBar('Processing files');

        expect(progress, equals(mockProgress));
        verify(() => logger.progress('Processing files')).called(1);
      });
    });

    group('listRules', () {
      test('logs available rules', () {
        logger.listRules(['rule1', 'rule2', 'rule3']);

        verify(() => logger.info('Available deprecation rules:')).called(1);
        verify(() => logger.info('  • rule1')).called(1);
        verify(() => logger.info('  • rule2')).called(1);
        verify(() => logger.info('  • rule3')).called(1);
      });
    });

    group('previewChange', () {
      test('logs change preview', () {
        logger.previewChange(
          filePath: '/test/file.dart',
          ruleName: 'withOpacity',
          change: 'Applied withOpacity rule',
        );

        verify(() => logger.info('')).called(1);
        verify(() => logger.info('Would apply in /test/file.dart:')).called(1);
        verify(() => logger.info('  Rule: withOpacity')).called(1);
        verify(
          () => logger.info('  Change: Applied withOpacity rule'),
        ).called(1);
      });
    });
  });
}
