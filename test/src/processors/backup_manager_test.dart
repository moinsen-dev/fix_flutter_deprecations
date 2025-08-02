import 'dart:io';

import 'package:fix_flutter_deprecations/src/processors/processors.dart';
import 'package:fix_flutter_deprecations/src/utils/utils.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

void main() {
  group('BackupManager', () {
    late MockLogger logger;
    late BackupManager backupManager;
    late Directory tempDir;
    late File testFile1;
    late File testFile2;

    setUp(() async {
      logger = MockLogger();
      when(() => logger.err(any())).thenReturn(null);
      when(() => logger.detail(any())).thenReturn(null);
      when(() => logger.info(any())).thenReturn(null);
      // Add logger extensions mocks
      when(() => logger.fileStart(any())).thenReturn(null);
      when(
        () => logger.fileComplete(
          any(),
          hasChanges: any(named: 'hasChanges'),
        ),
      ).thenReturn(null);
      when(() => logger.fileError(any(), any())).thenReturn(null);
      when(() => logger.ruleApplied(any(), any())).thenReturn(null);
      when(() => logger.backupCreated(any())).thenReturn(null);
      when(() => logger.backupRestored(any())).thenReturn(null);
      when(
        () => logger.progressBar(any(), total: any(named: 'total')),
      ).thenReturn(MockProgress());
      when(() => logger.listRules(any())).thenReturn(null);
      when(
        () => logger.previewChange(
          filePath: any(named: 'filePath'),
          ruleName: any(named: 'ruleName'),
          change: any(named: 'change'),
        ),
      ).thenReturn(null);
      when(
        () => logger.fixSummary(
          totalFiles: any(named: 'totalFiles'),
          filesModified: any(named: 'filesModified'),
          filesWithErrors: any(named: 'filesWithErrors'),
          elapsed: any(named: 'elapsed'),
        ),
      ).thenReturn(null);
      when(() => logger.dryRunNotice()).thenReturn(null);

      backupManager = BackupManager(logger: logger);
      tempDir = Directory.systemTemp.createTempSync('backup_manager_test_');
      testFile1 = File(path.join(tempDir.path, 'test1.dart'));
      testFile2 = File(path.join(tempDir.path, 'test2.dart'));
      await testFile1.writeAsString('content1');
      await testFile2.writeAsString('content2');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('createBackups', () {
      test('creates backups for all files', () async {
        final result = await backupManager.createBackups(
          [testFile1, testFile2],
        );

        expect(result, isTrue);
        expect(File('${testFile1.path}.backup').existsSync(), isTrue);
        expect(File('${testFile2.path}.backup').existsSync(), isTrue);
      });

      test('returns false and restores on error', () async {
        final badFile = File(path.join(tempDir.path, 'nonexistent.dart'));

        final result = await backupManager.createBackups([testFile1, badFile]);

        expect(result, isFalse);
        verify(() => logger.err(any())).called(greaterThanOrEqualTo(1));
      });

      test('clears previous backup list', () async {
        await backupManager.createBackups([testFile1]);
        await backupManager.createBackups([testFile2]);

        // Clean up should only affect testFile2
        await backupManager.cleanupBackups();

        expect(File('${testFile1.path}.backup').existsSync(), isTrue);
        expect(File('${testFile2.path}.backup').existsSync(), isFalse);
      });
    });

    group('restoreAllBackups', () {
      test('restores all backed up files', () async {
        await backupManager.createBackups([testFile1, testFile2]);
        await testFile1.writeAsString('modified1');
        await testFile2.writeAsString('modified2');

        await backupManager.restoreAllBackups();

        expect(await testFile1.readAsString(), equals('content1'));
        expect(await testFile2.readAsString(), equals('content2'));
        verify(() => logger.backupRestored(any<String>())).called(2);
      });

      test('handles restore errors gracefully', () async {
        await backupManager.createBackups([testFile1]);
        await File('${testFile1.path}.backup').delete();

        await backupManager.restoreAllBackups();

        verify(() => logger.err(any())).called(1);
      });
    });

    group('cleanupBackups', () {
      test('deletes all backup files', () async {
        await backupManager.createBackups([testFile1, testFile2]);

        await backupManager.cleanupBackups();

        expect(File('${testFile1.path}.backup').existsSync(), isFalse);
        expect(File('${testFile2.path}.backup').existsSync(), isFalse);
      });

      test('ignores errors when deleting backups', () async {
        await backupManager.createBackups([testFile1]);
        await File('${testFile1.path}.backup').delete();

        // Should not throw
        await backupManager.cleanupBackups();
      });
    });

    group('static methods', () {
      test('getBackupPath returns correct path', () {
        expect(
          BackupManager.getBackupPath('/path/to/file.dart'),
          equals('/path/to/file.dart.backup'),
        );
      });

      test('backupExists checks backup file existence', () {
        expect(BackupManager.backupExists(testFile1), isFalse);

        File('${testFile1.path}.backup').writeAsStringSync('backup');

        expect(BackupManager.backupExists(testFile1), isTrue);
      });

      test('findBackupFiles finds all backup files', () {
        File(
          path.join(tempDir.path, 'file1.dart.backup'),
        ).writeAsStringSync('backup1');
        File(
          path.join(tempDir.path, 'file2.dart.backup'),
        ).writeAsStringSync('backup2');
        File(path.join(tempDir.path, 'notbackup.txt')).writeAsStringSync('not');

        final backups = BackupManager.findBackupFiles(tempDir.path);

        expect(backups.length, equals(2));
        expect(backups.every((f) => f.path.endsWith('.backup')), isTrue);
      });

      test('findBackupFiles handles non-existent directory', () {
        final backups = BackupManager.findBackupFiles('/nonexistent');
        expect(backups, isEmpty);
      });

      test('findBackupFiles finds backups recursively', () {
        final subDir = Directory(path.join(tempDir.path, 'sub'))..createSync();

        File(
          path.join(tempDir.path, 'root.dart.backup'),
        ).writeAsStringSync('backup1');
        File(
          path.join(subDir.path, 'sub.dart.backup'),
        ).writeAsStringSync('backup2');

        final backups = BackupManager.findBackupFiles(tempDir.path);

        expect(backups.length, equals(2));
      });
    });

    group('removeOrphanedBackups', () {
      test('removes orphaned backup files', () async {
        // Create orphaned backup
        final orphanedBackup = File(
          path.join(tempDir.path, 'orphan.dart.backup'),
        );
        await orphanedBackup.writeAsString('orphaned');

        // Create valid backup pair
        await testFile1.writeAsString('original');
        await File('${testFile1.path}.backup').writeAsString('backup');

        final count = await backupManager.removeOrphanedBackups(tempDir.path);

        expect(count, equals(1));
        expect(orphanedBackup.existsSync(), isFalse);
        expect(File('${testFile1.path}.backup').existsSync(), isTrue);
        verify(() => logger.info('Removed 1 orphaned backup files')).called(1);
      });

      test('handles no orphaned files', () async {
        await testFile1.writeAsString('original');
        await File('${testFile1.path}.backup').writeAsString('backup');

        final count = await backupManager.removeOrphanedBackups(tempDir.path);

        expect(count, equals(0));
        verifyNever(() => logger.info(any()));
      });

      test('ignores errors when deleting', () async {
        if (Platform.isWindows) {
          // Skip this test on Windows as file permissions work differently
          return;
        }

        final orphanedBackup = File(
          path.join(tempDir.path, 'orphan.dart.backup'),
        );
        await orphanedBackup.writeAsString('orphaned');

        // Make file read-only
        await Process.run('chmod', ['444', orphanedBackup.path]);

        final count = await backupManager.removeOrphanedBackups(tempDir.path);

        // Restore permissions for cleanup
        await Process.run('chmod', ['644', orphanedBackup.path]);

        expect(count, equals(0));
      });
    });
  });
}
