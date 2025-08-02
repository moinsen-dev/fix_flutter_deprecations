import 'dart:io';
import 'package:path/path.dart' as path;

/// Utility functions for file operations.
class FileUtils {
  /// Private constructor to prevent instantiation.
  FileUtils._();

  /// Finds all Dart files in the given path.
  ///
  /// If [targetPath] is a file, returns a list containing only that file.
  /// If [targetPath] is a directory, recursively finds all .dart files.
  static Future<List<File>> findDartFiles(String targetPath) async {
    final entity = FileSystemEntity.typeSync(targetPath);

    if (entity == FileSystemEntityType.file) {
      final file = File(targetPath);
      if (path.extension(file.path) == '.dart') {
        return [file];
      }
      return [];
    }

    if (entity == FileSystemEntityType.directory) {
      final files = <File>[];
      final dir = Directory(targetPath);

      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && path.extension(entity.path) == '.dart') {
          // Skip generated files
          if (!entity.path.contains('.g.dart') &&
              !entity.path.contains('.freezed.dart')) {
            files.add(entity);
          }
        }
      }

      return files;
    }

    throw ArgumentError('Path does not exist: $targetPath');
  }

  /// Reads the content of a file.
  static Future<String> readFile(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read file ${file.path}: $e');
    }
  }

  /// Writes content to a file.
  static Future<void> writeFile(File file, String content) async {
    try {
      await file.writeAsString(content);
    } catch (e) {
      throw Exception('Failed to write file ${file.path}: $e');
    }
  }

  /// Creates a backup of the file.
  static Future<File> createBackup(File file) async {
    final backupPath = '${file.path}.backup';
    try {
      return await file.copy(backupPath);
    } catch (e) {
      throw Exception('Failed to create backup of ${file.path}: $e');
    }
  }

  /// Restores a file from its backup.
  static Future<void> restoreFromBackup(File file) async {
    final backupPath = '${file.path}.backup';
    final backup = File(backupPath);

    if (!backup.existsSync()) {
      throw Exception('Backup file does not exist: $backupPath');
    }

    try {
      await backup.copy(file.path);
      await backup.delete();
    } catch (e) {
      throw Exception('Failed to restore backup of ${file.path}: $e');
    }
  }

  /// Deletes a backup file.
  static Future<void> deleteBackup(File file) async {
    final backupPath = '${file.path}.backup';
    final backup = File(backupPath);

    if (backup.existsSync()) {
      try {
        await backup.delete();
      } on FileSystemException {
        // Ignore errors when deleting backup
      }
    }
  }

  /// Gets the relative path from a base directory.
  static String getRelativePath(String filePath, String basePath) {
    return path.relative(filePath, from: basePath);
  }
}
