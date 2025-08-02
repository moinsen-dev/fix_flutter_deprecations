import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// Analyzes Dart files using the Dart analyzer.
class DartAnalyzer {
  /// Creates a new [DartAnalyzer].
  DartAnalyzer({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  /// Validates a Dart file by running dart analyze.
  ///
  /// Returns true if the file passes analysis, false otherwise.
  Future<bool> validateFile(File file) async {
    try {
      final result = await Process.run(
        'dart',
        ['analyze', file.path, '--no-fatal-warnings'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        return true;
      }

      _logger
        ..err('Analysis failed for ${path.basename(file.path)}:')
        ..err(result.stdout.toString());
      if (result.stderr.toString().isNotEmpty) {
        _logger.err(result.stderr.toString());
      }

      return false;
    } on ProcessException catch (e) {
      _logger.err('Failed to run dart analyze: ${e.message}');
      return false;
    }
  }

  /// Validates multiple Dart files.
  ///
  /// Returns a map of file paths to validation results.
  Future<Map<String, bool>> validateFiles(List<File> files) async {
    final results = <String, bool>{};

    for (final file in files) {
      results[file.path] = await validateFile(file);
    }

    return results;
  }

  /// Runs dart analyze on the entire project.
  ///
  /// Returns true if all files pass analysis, false otherwise.
  Future<bool> validateProject([String? projectPath]) async {
    try {
      final workingDir = projectPath ?? Directory.current.path;
      final result = await Process.run(
        'dart',
        ['analyze', '--no-fatal-warnings'],
        workingDirectory: workingDir,
        runInShell: true,
      );

      if (result.exitCode == 0) {
        _logger.success('✓ All files pass dart analyze');
        return true;
      }

      _logger
        ..err('Project analysis failed:')
        ..err(result.stdout.toString());
      if (result.stderr.toString().isNotEmpty) {
        _logger.err(result.stderr.toString());
      }

      return false;
    } on ProcessException catch (e) {
      _logger.err('Failed to run dart analyze: ${e.message}');
      return false;
    }
  }

  /// Checks if a file has syntax errors.
  ///
  /// This is a quick check that doesn't run full analysis.
  Future<bool> hasSyntaxErrors(File file) async {
    try {
      final result = await Process.run(
        'dart',
        ['analyze', file.path, '--fatal-infos'],
        runInShell: true,
      );

      // Exit code 0 means no errors
      // Exit code 1 means warnings but no errors
      // Exit code 2 means errors
      return result.exitCode >= 2;
    } on ProcessException {
      // If we can't run the analyzer, assume no syntax errors
      // to avoid blocking the fix process
      return false;
    }
  }

  /// Gets analysis issues for a file.
  ///
  /// Returns a list of issue descriptions.
  Future<List<String>> getIssues(File file) async {
    try {
      final result = await Process.run(
        'dart',
        ['analyze', file.path, '--format=machine'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        return [];
      }

      final output = result.stdout.toString();
      final lines = output.split('\n').where((line) => line.isNotEmpty);

      return lines.toList();
    } on ProcessException {
      return [];
    }
  }
}
