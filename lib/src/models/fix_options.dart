import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Configuration options for Flutter deprecation fix operations.
///
/// This class encapsulates all the settings and parameters that control
/// how deprecation fixes are applied to files. It provides a flexible
/// way to customize the behavior of the fix process.
///
/// ## Example Usage
///
/// ```dart
/// // Basic usage with defaults
/// final options = FixOptions(targetPath: 'lib/');
///
/// // Dry run with specific rules
/// final dryRunOptions = FixOptions(
///   targetPath: 'lib/',
///   dryRun: true,
///   rules: ['withOpacity', 'surfaceContainerHighest'],
///   verbose: true,
/// );
///
/// // No backup mode
/// final noBackupOptions = FixOptions(
///   targetPath: 'lib/',
///   backup: false,
/// );
/// ```
@immutable
class FixOptions extends Equatable {
  /// Creates a new [FixOptions] instance.
  const FixOptions({
    required this.targetPath,
    this.dryRun = false,
    this.backup = true,
    this.verbose = false,
    this.rules,
  });

  /// The target path to fix (file or directory).
  final String targetPath;

  /// Whether to run in dry-run mode (no actual changes).
  final bool dryRun;

  /// Whether to create backups before modifying files.
  final bool backup;

  /// Whether to show verbose output.
  final bool verbose;

  /// Specific rules to apply (null means all rules).
  final List<String>? rules;

  /// Creates a copy of this [FixOptions] with the given fields replaced.
  FixOptions copyWith({
    String? targetPath,
    bool? dryRun,
    bool? backup,
    bool? verbose,
    List<String>? rules,
  }) {
    return FixOptions(
      targetPath: targetPath ?? this.targetPath,
      dryRun: dryRun ?? this.dryRun,
      backup: backup ?? this.backup,
      verbose: verbose ?? this.verbose,
      rules: rules ?? this.rules,
    );
  }

  @override
  List<Object?> get props => [targetPath, dryRun, backup, verbose, rules];
}
