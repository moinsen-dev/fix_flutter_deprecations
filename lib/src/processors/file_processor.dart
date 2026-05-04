import 'dart:io';

import 'package:fix_flutter_deprecations/src/models/models.dart';
import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:fix_flutter_deprecations/src/utils/utils.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// Processes Dart files to apply Flutter deprecation fixes.
///
/// This class handles the core file processing logic for applying
/// deprecation rules to individual files or collections of files.
/// It manages file I/O, backup creation, progress reporting, and
/// error handling during the transformation process.
///
/// ## Usage
///
/// ```dart
/// final processor = FileProcessor(logger: logger);
/// final result = await processor.processFile(file, options);
///
/// if (result.isSuccess && result.hasChanges) {
///   print('Applied rules: ${result.appliedRules.join(', ')}');
/// }
/// ```
///
/// ## Features
///
/// - **Safe transformations**: Validates changes before applying them
/// - **Backup support**: Creates backups before modifying files
/// - **Dry run mode**: Preview changes without modifying files
/// - **Progress reporting**: Shows progress for bulk operations
/// - **Error handling**: Gracefully handles and reports file errors
class FileProcessor {
  /// Creates a new [FileProcessor].
  ///
  /// Parameters:
  /// - [logger]: The logger instance for progress reporting and error handling
  FileProcessor({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  /// Processes a single file with the given options.
  ///
  /// This method reads the specified [file], applies the relevant deprecation
  /// rules based on the provided [options], and returns a [FixResult]
  /// containing information about the applied changes.
  ///
  /// The processing includes:
  /// 1. Reading the file content
  /// 2. Applying matching deprecation rules
  /// 3. Validating transformations for safety
  /// 4. Creating backups (if enabled)
  /// 5. Writing modified content (unless dry run)
  ///
  /// Parameters:
  /// - [file]: The Dart file to process
  /// - [options]: Processing options including rules filter, dry run mode, etc.
  ///
  /// Returns a [FixResult] indicating success/failure and applied changes.
  ///
  /// Throws: No exceptions are thrown; errors are captured in the result.
  Future<FixResult> processFile(
    File file,
    FixOptions options,
  ) async {
    final filePath = FileUtils.getRelativePath(
      file.path,
      Directory.current.path,
    );

    try {
      // Read file content
      final content = await FileUtils.readFile(file);

      // Honour an opt-out marker at the top of the file. The marker is
      // intended for files that contain test fixtures or example snippets
      // which would otherwise trip the rules' regexes.
      if (_hasFileIgnoreMarker(content)) {
        return FixResult.success(
          filePath: filePath,
          appliedRules: const [],
          changes: const [],
        );
      }

      var modifiedContent = content;

      // Get rules to apply, filtered by file extension / basename.
      final fileExt = path.extension(file.path);
      final fileBasename = path.basename(file.path);
      final rules = RuleRegistry.getRules(options.rules).where((rule) {
        return rule.appliesToExtensions.contains(fileExt) ||
            rule.appliesToExtensions.contains(fileBasename);
      }).toList();
      final appliedRules = <String>[];
      final changes = <String>[];

      // Apply each rule
      for (final rule in rules) {
        if (rule.matches(modifiedContent)) {
          final originalContent = modifiedContent;
          modifiedContent = rule.apply(modifiedContent);

          if (rule.validate(originalContent, modifiedContent)) {
            appliedRules.add(rule.name);
            changes.add('Applied ${rule.name}: ${rule.description}');

            if (options.verbose) {
              _logger.ruleApplied(rule.name, filePath);
            }
          } else {
            // Revert if validation fails
            modifiedContent = originalContent;
            _logger.warn(
              'Rule ${rule.name} validation failed for $filePath',
            );
          }
        }
      }

      // Check if any changes were made
      final hasChanges = modifiedContent != content;

      if (hasChanges && !options.dryRun) {
        // Create backup if requested
        if (options.backup) {
          await FileUtils.createBackup(file);
          if (options.verbose) {
            _logger.backupCreated(filePath);
          }
        }

        // Write modified content
        await FileUtils.writeFile(file, modifiedContent);
      }

      // Preview changes in dry run mode
      if (hasChanges && options.dryRun) {
        for (var i = 0; i < appliedRules.length; i++) {
          _logger.previewChange(
            filePath: filePath,
            ruleName: appliedRules[i],
            change: changes[i],
          );
        }
      }

      return FixResult.success(
        filePath: filePath,
        appliedRules: appliedRules,
        changes: changes,
      );
    } on Exception catch (e) {
      return FixResult.failure(
        filePath: filePath,
        error: e.toString(),
      );
    }
  }

  /// File-level opt-out marker. A file whose first 10 non-blank lines
  /// contain the string `fix_flutter_deprecations: ignore_file` is left
  /// completely untouched. Useful for test fixtures or examples that
  /// would otherwise trip the rules' regexes.
  static const ignoreFileMarker = 'fix_flutter_deprecations: ignore_file';

  bool _hasFileIgnoreMarker(String content) {
    var nonBlank = 0;
    for (final raw in content.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        continue;
      }
      if (line.contains(ignoreFileMarker)) {
        return true;
      }
      nonBlank++;
      if (nonBlank >= 10) {
        return false;
      }
    }
    return false;
  }

  /// Processes multiple files with the given options.
  Future<List<FixResult>> processFiles(
    List<File> files,
    FixOptions options,
  ) async {
    final results = <FixResult>[];
    final progress = options.verbose
        ? null
        : _logger.progressBar('Processing files', total: files.length);

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final result = await processFile(file, options);
      results.add(result);

      if (options.verbose) {
        final relativePath = FileUtils.getRelativePath(
          file.path,
          Directory.current.path,
        );

        if (result.isSuccess) {
          _logger.fileComplete(relativePath, hasChanges: result.hasChanges);
        } else {
          _logger.fileError(relativePath, result.error ?? 'Unknown error');
        }
      } else {
        progress?.update('${i + 1}/${files.length}');
      }
    }

    progress?.complete();
    return results;
  }
}
