import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fix_flutter_deprecations/src/models/models.dart';
import 'package:fix_flutter_deprecations/src/processors/processors.dart';
import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:fix_flutter_deprecations/src/utils/utils.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template fix_command}
/// Command to fix Flutter deprecations in Dart files.
/// {@endtemplate}
class FixCommand extends Command<int> {
  /// {@macro fix_command}
  FixCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: 'Preview changes without modifying files',
        negatable: false,
      )
      ..addFlag(
        'no-backup',
        help: 'Skip creating backup files',
        negatable: false,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show detailed output',
        negatable: false,
      )
      ..addMultiOption(
        'rules',
        abbr: 'r',
        help: 'Specific rules to apply (default: all)',
        allowed: RuleRegistry.availableRuleNames,
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Path to file or directory to fix',
        defaultsTo: '.',
      );
  }

  final Logger _logger;

  @override
  String get description => 'Fix Flutter deprecations in your codebase';

  @override
  String get name => 'fix';

  @override
  Future<int> run() async {
    final stopwatch = Stopwatch()..start();

    // Parse options
    final options = FixOptions(
      targetPath: argResults!['path'] as String,
      dryRun: argResults!['dry-run'] as bool,
      backup: !(argResults!['no-backup'] as bool),
      verbose: argResults!['verbose'] as bool,
      rules: (argResults!['rules'] as List<String>).isEmpty
          ? null
          : argResults!['rules'] as List<String>,
    );

    // Show dry run notice
    if (options.dryRun) {
      _logger.dryRunNotice();
    }

    // Validate rules if specified
    if (options.rules != null) {
      final invalidRules = RuleRegistry.getInvalidRuleNames(options.rules!);
      if (invalidRules.isNotEmpty) {
        _logger
          ..err('Unknown rules: ${invalidRules.join(', ')}')
          ..info(
            'Available rules: ${RuleRegistry.availableRuleNames.join(', ')}',
          );
        return ExitCode.usage.code;
      }
    }

    // Find Dart files
    List<File> files;
    try {
      files = await FileUtils.findDartFiles(options.targetPath);

      if (files.isEmpty) {
        _logger.warn('No Dart files found in ${options.targetPath}');
        return ExitCode.success.code;
      }

      _logger.info('Found ${files.length} Dart file(s) to process');

      // Create file processor
      final processor = FileProcessor(logger: _logger);

      // Process files
      final results = await processor.processFiles(files, options);

      // Count results
      final modifiedCount = results.where((r) => r.hasChanges).length;
      final errorCount = results.where((r) => r.isFailure).length;

      // Show summary
      _logger.fixSummary(
        totalFiles: files.length,
        filesModified: modifiedCount,
        filesWithErrors: errorCount,
        elapsed: stopwatch.elapsed,
      );

      // Run dart analyze if not in dry run mode and files were modified
      if (!options.dryRun && modifiedCount > 0) {
        _logger.info('Running dart analyze to verify changes...');
        final analyzer = DartAnalyzer(logger: _logger);
        final analysisSuccess = await analyzer.validateProject();

        if (!analysisSuccess) {
          _logger.warn(
            'Some files have analysis issues. '
            'You may need to manually fix them.',
          );
        }
      }

      return errorCount > 0 ? ExitCode.software.code : ExitCode.success.code;
    } on FileSystemException catch (e) {
      _logger.err('File system error: ${e.message}');
      return ExitCode.ioError.code;
    } on Exception catch (e) {
      _logger.err('Unexpected error: $e');
      return ExitCode.software.code;
    }
  }
}
