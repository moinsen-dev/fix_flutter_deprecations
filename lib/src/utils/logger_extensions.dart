import 'package:mason_logger/mason_logger.dart';

/// Extension methods for enhanced logging functionality.
extension LoggerExtensions on Logger {
  /// Logs a file processing start message.
  void fileStart(String filePath) {
    detail('Processing: $filePath');
  }

  /// Logs a file processing completion message.
  void fileComplete(String filePath, {required bool hasChanges}) {
    if (hasChanges) {
      success('✓ Fixed: $filePath');
    } else {
      detail('✓ No changes: $filePath');
    }
  }

  /// Logs a file processing error.
  void fileError(String filePath, String error) {
    err('✗ Error in $filePath: $error');
  }

  /// Logs a rule application message.
  void ruleApplied(String ruleName, String filePath) {
    detail('  Applied rule "$ruleName" to $filePath');
  }

  /// Logs a summary of the fix operation.
  void fixSummary({
    required int totalFiles,
    required int filesModified,
    required int filesWithErrors,
    required Duration elapsed,
  }) {
    info('');
    info('Summary:');
    info('  Total files scanned: $totalFiles');
    info('  Files modified: $filesModified');
    if (filesWithErrors > 0) {
      warn('  Files with errors: $filesWithErrors');
    }
    info('  Time elapsed: ${elapsed.inSeconds}s');
    info('');
  }

  /// Logs a dry run notice.
  void dryRunNotice() {
    warn(
      'Running in DRY RUN mode. No files will be modified.',
    );
    info('');
  }

  /// Logs a backup creation message.
  void backupCreated(String filePath) {
    detail('  Created backup: $filePath.backup');
  }

  /// Logs a backup restoration message.
  void backupRestored(String filePath) {
    warn('  Restored from backup: $filePath');
  }

  /// Shows a progress indicator for long operations.
  Progress progressBar(String message, {int? total}) {
    return progress(message);
  }

  /// Logs available rules.
  void listRules(List<String> rules) {
    info('Available deprecation rules:');
    for (final rule in rules) {
      info('  • $rule');
    }
  }

  /// Logs a change preview in dry run mode.
  void previewChange({
    required String filePath,
    required String ruleName,
    required String change,
  }) {
    info('');
    info('Would apply in $filePath:');
    info('  Rule: $ruleName');
    info('  Change: $change');
  }
}
