import 'dart:io';

import 'package:fix_flutter_deprecations/src/utils/utils.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// Manages file backups during the fix process.
class BackupManager {
  /// Creates a new [BackupManager].
  BackupManager({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;
  final List<File> _backedUpFiles = [];

  /// Creates backups for all files.
  ///
  /// Returns true if all backups were created successfully.
  Future<bool> createBackups(List<File> files) async {
    _backedUpFiles.clear();

    for (final file in files) {
      try {
        await FileUtils.createBackup(file);
        _backedUpFiles.add(file);
      } on Exception catch (e) {
        _logger.err('Failed to create backup for ${file.path}: $e');

        // Restore any backups we've already created
        await restoreAllBackups();
        return false;
      }
    }

    return true;
  }

  /// Restores all backed up files.
  ///
  /// This is typically called when an error occurs during processing.
  Future<void> restoreAllBackups() async {
    for (final file in _backedUpFiles) {
      try {
        await FileUtils.restoreFromBackup(file);
        _logger.backupRestored(
          FileUtils.getRelativePath(file.path, Directory.current.path),
        );
      } on Exception catch (e) {
        _logger.err('Failed to restore backup for ${file.path}: $e');
      }
    }
    _backedUpFiles.clear();
  }

  /// Cleans up all backup files.
  ///
  /// This is typically called after successful processing.
  Future<void> cleanupBackups() async {
    for (final file in _backedUpFiles) {
      try {
        await FileUtils.deleteBackup(file);
      } on Exception {
        // Ignore errors when deleting backups
      }
    }
    _backedUpFiles.clear();
  }

  /// Gets the backup file path for a given file.
  static String getBackupPath(String filePath) {
    return '$filePath.backup';
  }

  /// Checks if a backup exists for the given file.
  static bool backupExists(File file) {
    final backupFile = File(getBackupPath(file.path));
    return backupFile.existsSync();
  }

  /// Gets a list of all backup files in a directory.
  static List<File> findBackupFiles(String directoryPath) {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      return [];
    }

    final backupFiles = <File>[];

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.backup')) {
        backupFiles.add(entity);
      }
    }

    return backupFiles;
  }

  /// Removes orphaned backup files.
  ///
  /// Orphaned backups are .backup files without corresponding original files.
  Future<int> removeOrphanedBackups(String directoryPath) async {
    final backupFiles = findBackupFiles(directoryPath);
    var removedCount = 0;

    for (final backupFile in backupFiles) {
      final originalPath = backupFile.path.replaceAll('.backup', '');
      final originalFile = File(originalPath);

      if (!originalFile.existsSync()) {
        try {
          await backupFile.delete();
          removedCount++;
          _logger.detail(
            'Removed orphaned backup: ${path.basename(backupFile.path)}',
          );
        } on FileSystemException {
          // Ignore errors when deleting orphaned backups
        }
      }
    }

    if (removedCount > 0) {
      _logger.info('Removed $removedCount orphaned backup files');
    }

    return removedCount;
  }
}
