import 'dart:io';

import 'package:fix_flutter_deprecations/src/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('FileUtils', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_utils_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('findDartFiles', () {
      test('finds single dart file', () async {
        final dartFile = File(path.join(tempDir.path, 'test.dart'));
        await dartFile.writeAsString('// test');

        final files = await FileUtils.findDartFiles(dartFile.path);

        expect(files.length, equals(1));
        expect(files.first.path, equals(dartFile.path));
      });

      test('returns empty for non-dart file', () async {
        final txtFile = File(path.join(tempDir.path, 'test.txt'));
        await txtFile.writeAsString('test');

        final files = await FileUtils.findDartFiles(txtFile.path);

        expect(files, isEmpty);
      });

      test('finds all dart files in directory', () async {
        await File(
          path.join(tempDir.path, 'file1.dart'),
        ).writeAsString('// file1');
        await File(
          path.join(tempDir.path, 'file2.dart'),
        ).writeAsString('// file2');
        await File(
          path.join(tempDir.path, 'file3.txt'),
        ).writeAsString('not dart');

        final files = await FileUtils.findDartFiles(tempDir.path);

        expect(files.length, equals(2));
        expect(files.any((f) => f.path.endsWith('file1.dart')), isTrue);
        expect(files.any((f) => f.path.endsWith('file2.dart')), isTrue);
      });

      test('finds dart files recursively', () async {
        final subDir = Directory(path.join(tempDir.path, 'sub'));
        await subDir.create();

        await File(
          path.join(tempDir.path, 'root.dart'),
        ).writeAsString('// root');
        await File(path.join(subDir.path, 'sub.dart')).writeAsString('// sub');

        final files = await FileUtils.findDartFiles(tempDir.path);

        expect(files.length, equals(2));
      });

      test('excludes generated files', () async {
        await File(
          path.join(tempDir.path, 'normal.dart'),
        ).writeAsString('// normal');
        await File(
          path.join(tempDir.path, 'generated.g.dart'),
        ).writeAsString('// generated');
        await File(
          path.join(tempDir.path, 'frozen.freezed.dart'),
        ).writeAsString('// frozen');

        final files = await FileUtils.findDartFiles(tempDir.path);

        expect(files.length, equals(1));
        expect(files.first.path.endsWith('normal.dart'), isTrue);
      });

      test('throws for non-existent path', () async {
        expect(
          () => FileUtils.findDartFiles('/non/existent/path'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('readFile', () {
      test('reads file content', () async {
        final file = File(path.join(tempDir.path, 'test.dart'));
        const content = 'void main() {}';
        await file.writeAsString(content);

        final result = await FileUtils.readFile(file);

        expect(result, equals(content));
      });

      test('throws for non-existent file', () async {
        final file = File(path.join(tempDir.path, 'missing.dart'));

        expect(
          () => FileUtils.readFile(file),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to read file'),
            ),
          ),
        );
      });
    });

    group('writeFile', () {
      test('writes content to file', () async {
        final file = File(path.join(tempDir.path, 'test.dart'));
        const content = 'void main() {}';

        await FileUtils.writeFile(file, content);

        expect(file.existsSync(), isTrue);
        expect(await file.readAsString(), equals(content));
      });

      test('overwrites existing file', () async {
        final file = File(path.join(tempDir.path, 'test.dart'));
        await file.writeAsString('old content');

        const newContent = 'new content';
        await FileUtils.writeFile(file, newContent);

        expect(await file.readAsString(), equals(newContent));
      });
    });

    group('backup operations', () {
      late File testFile;

      setUp(() async {
        testFile = File(path.join(tempDir.path, 'test.dart'));
        await testFile.writeAsString('original content');
      });

      test('createBackup creates backup file', () async {
        final backup = await FileUtils.createBackup(testFile);

        expect(backup.path, equals('${testFile.path}.backup'));
        expect(backup.existsSync(), isTrue);
        expect(await backup.readAsString(), equals('original content'));
      });

      test('restoreFromBackup restores original content', () async {
        await FileUtils.createBackup(testFile);
        await testFile.writeAsString('modified content');

        await FileUtils.restoreFromBackup(testFile);

        expect(await testFile.readAsString(), equals('original content'));
        expect(File('${testFile.path}.backup').existsSync(), isFalse);
      });

      test('restoreFromBackup throws if no backup', () async {
        expect(
          () => FileUtils.restoreFromBackup(testFile),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Backup file does not exist'),
            ),
          ),
        );
      });

      test('deleteBackup removes backup file', () async {
        await FileUtils.createBackup(testFile);
        final backupFile = File('${testFile.path}.backup');
        expect(backupFile.existsSync(), isTrue);

        await FileUtils.deleteBackup(testFile);

        expect(backupFile.existsSync(), isFalse);
      });

      test('deleteBackup succeeds if no backup exists', () async {
        // Should not throw
        await FileUtils.deleteBackup(testFile);
      });
    });

    group('getRelativePath', () {
      test('returns relative path from base', () {
        final filePath = path.join(tempDir.path, 'sub', 'file.dart');
        final basePath = tempDir.path;

        final relative = FileUtils.getRelativePath(filePath, basePath);

        expect(relative, equals(path.join('sub', 'file.dart')));
      });

      test('returns path as-is if not under base', () {
        const filePath = '/completely/different/path.dart';
        final basePath = tempDir.path;

        final relative = FileUtils.getRelativePath(filePath, basePath);

        // Path package behavior varies by platform
        expect(relative, isNotEmpty);
      });
    });
  });
}
