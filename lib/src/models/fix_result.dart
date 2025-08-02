import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents the result of a Flutter deprecation fix operation on a file.
///
/// This class encapsulates all information about the outcome of processing
/// a file for deprecation fixes, including success/failure status, applied
/// rules, changes made, and any errors encountered.
///
/// ## Usage Examples
///
/// ```dart
/// // Check if the operation was successful
/// if (result.isSuccess && result.hasChanges) {
///   print('Fixed ${result.appliedRules.length} deprecations in '
///         '${result.filePath}');
///   for (final change in result.changes) {
///     print('  - $change');
///   }
/// }
///
/// // Handle errors
/// if (result.isFailure) {
///   print('Failed to process ${result.filePath}: ${result.error}');
/// }
///
/// // Export to JSON for reporting
/// final jsonData = result.toJson();
/// ```
///
/// ## Factory Constructors
///
/// Use [FixResult.success] for successful operations and [FixResult.failure]
/// for operations that encountered errors.
@immutable
class FixResult extends Equatable {
  /// Creates a new [FixResult] instance.
  const FixResult({
    required this.filePath,
    required this.hasChanges,
    required this.appliedRules,
    required this.changes,
    this.error,
  });

  /// Creates a successful fix result.
  factory FixResult.success({
    required String filePath,
    required List<String> appliedRules,
    required List<String> changes,
  }) {
    return FixResult(
      filePath: filePath,
      hasChanges: changes.isNotEmpty,
      appliedRules: appliedRules,
      changes: changes,
    );
  }

  /// Creates a failed fix result.
  factory FixResult.failure({
    required String filePath,
    required String error,
  }) {
    return FixResult(
      filePath: filePath,
      hasChanges: false,
      appliedRules: const [],
      changes: const [],
      error: error,
    );
  }

  /// The path of the file that was processed.
  final String filePath;

  /// Whether the file had any changes applied.
  final bool hasChanges;

  /// List of rule names that were applied.
  final List<String> appliedRules;

  /// Descriptions of the changes made.
  final List<String> changes;

  /// Error message if the operation failed.
  final String? error;

  /// Whether the fix operation succeeded.
  bool get isSuccess => error == null;

  /// Whether the fix operation failed.
  bool get isFailure => error != null;

  /// Converts this result to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'hasChanges': hasChanges,
      'appliedRules': appliedRules,
      'changes': changes,
      if (error != null) 'error': error,
    };
  }

  @override
  List<Object?> get props => [
    filePath,
    hasChanges,
    appliedRules,
    changes,
    error,
  ];
}
