import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:fix_flutter_deprecations/src/commands/commands.dart';
import 'package:fix_flutter_deprecations/src/models/models.dart';
import 'package:fix_flutter_deprecations/src/processors/processors.dart';
import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:fix_flutter_deprecations/src/utils/utils.dart';
import 'package:fix_flutter_deprecations/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

const executableName = 'fix_deprecations';
const packageName = 'fix_flutter_deprecations';
const description = 'Flutter Deprecation Fixer';

/// {@template fix_flutter_deprecations_command_runner}
/// A [CommandRunner] for the CLI.
///
/// ```bash
/// $ fix_deprecations --version
/// ```
/// {@endtemplate}
class FixFlutterDeprecationsCommandRunner extends CompletionCommandRunner<int> {
  /// {@macro fix_flutter_deprecations_command_runner}
  FixFlutterDeprecationsCommandRunner({Logger? logger, PubUpdater? pubUpdater})
    : _logger = logger ?? Logger(),
      _pubUpdater = pubUpdater ?? PubUpdater(),
      super(executableName, description) {
    // Add root options and flags
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show detailed output',
        negatable: false,
      )
      ..addFlag(
        'list-rules',
        abbr: 'l',
        help: 'List all available deprecation rules',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: 'Show what would be changed without making changes',
        negatable: false,
      )
      ..addFlag(
        'backup',
        abbr: 'b',
        help: 'Create backup files (.bak)',
        negatable: false,
      )
      ..addMultiOption(
        'rules',
        abbr: 'r',
        help: 'Comma-separated list of rules to apply (default: all)',
      );

    // Add sub commands
    addCommand(UpdateCommand(logger: _logger, pubUpdater: _pubUpdater));
  }

  @override
  void printUsage() {
    _logger.info('''
Flutter Deprecation Fixer

Usage: $executableName [OPTIONS] [target]

Options:
  -b, --backup          Create backup files (.bak)
  -d, --dry-run         Show what would be changed without making changes
  -v, --verbose         Show detailed output
  -r, --rules RULES     Comma-separated list of rules to apply (default: all)
  -l, --list-rules      List all available deprecation rules
  -h, --help            Show this help message
      --version         Print the current version

Arguments:
  target                Path to a file, directory, or project root
                        (default: current directory).
                        Project roots are also scanned for pubspec.yaml
                        and analysis_options.yaml.

Examples:
  $executableName                              # Fix everything in current dir + yaml configs
  $executableName -l                           # List the 15 available rules
  $executableName -d                           # Dry run — preview without writing
  $executableName -r cascadeInvocations lib/   # Apply only one rule
  $executableName -r sortPubDependencies .     # Sort pubspec.yaml dependencies
  $executableName -d -v .                      # Dry run with verbose per-file output
  $executableName -b path/to/file.dart         # Fix single file, leave a .backup

Notes:
  - Files matching .g.dart and .freezed.dart are skipped.
  - .dart_tool/, build/, .fvm/ directories are skipped.
  - A file containing `// fix_flutter_deprecations: ignore_file` near
    the top is left untouched.
  - No backup files are created by default; use -b if you want them.

Use --list-rules to see the full set of rules with descriptions.
''');
  }

  final Logger _logger;
  final PubUpdater _pubUpdater;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      if (topLevelResults['verbose'] == true) {
        _logger.level = Level.verbose;
      }
      return await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      // On format errors, show the commands error message, root usage and
      // exit with an error code
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    // Fast track completion command
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }

    // Handle version flag
    if (topLevelResults['version'] == true) {
      _logger.info(packageVersion);
      await _checkForUpdates();
      return ExitCode.success.code;
    }

    // Handle --help / -h flag or no arguments
    if (topLevelResults.arguments.isEmpty || topLevelResults['help'] == true) {
      printUsage();
      return ExitCode.success.code;
    }

    // Handle list-rules flag
    if (topLevelResults['list-rules'] == true) {
      await _listRules(topLevelResults['verbose'] as bool);
      return ExitCode.success.code;
    }

    // If there's a subcommand, run it
    if (topLevelResults.command != null) {
      final exitCode = await super.runCommand(topLevelResults);
      // Check for updates
      if (topLevelResults.command?.name != UpdateCommand.commandName) {
        await _checkForUpdates();
      }
      return exitCode;
    }

    // Otherwise, run the fix command with the provided options
    final exitCode = await _runFixCommand(topLevelResults);

    // Check for updates
    await _checkForUpdates();

    return exitCode;
  }

  /// Lists all available deprecation fix rules
  Future<void> _listRules(bool verbose) async {
    _logger.info('Available Flutter deprecation fix rules:\n');

    for (final rule in RuleRegistry.allRules) {
      if (verbose) {
        _logger
          ..info(lightCyan.wrap('• ${rule.name}') ?? rule.name)
          ..info('  Description: ${rule.description}')
          ..info('  Pattern: ${rule.deprecatedPattern}')
          ..info('  Replacement: ${rule.replacementExample}')
          ..info('');
      } else {
        final name = lightCyan.wrap(rule.name) ?? rule.name;
        _logger.info('• $name - ${rule.description}');
      }
    }

    if (!verbose) {
      _logger
        ..info('')
        ..info(
          'Use ${lightCyan.wrap('--verbose')} flag for detailed information',
        );
    }

    _logger
      ..info('')
      ..info(
        'To apply specific rules, use: '
        '${lightCyan.wrap('$executableName --rules rule1,rule2')}',
      );
  }

  /// Runs the fix command with default behavior
  Future<int> _runFixCommand(ArgResults topLevelResults) async {
    final stopwatch = Stopwatch()..start();

    // Get target path from rest arguments or use current directory
    final targetPath = topLevelResults.rest.isEmpty
        ? '.'
        : topLevelResults.rest.first;

    // Parse options
    final options = FixOptions(
      targetPath: targetPath,
      dryRun: topLevelResults['dry-run'] as bool,
      backup: topLevelResults['backup'] as bool,
      verbose: topLevelResults['verbose'] as bool,
      rules: (topLevelResults['rules'] as List<String>).isEmpty
          ? null
          : topLevelResults['rules'] as List<String>,
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
      files = await FileUtils.findProjectFiles(options.targetPath);

      if (files.isEmpty) {
        _logger.warn('No Dart or config files found in ${options.targetPath}');
        return ExitCode.success.code;
      }

      _logger.info('Found ${files.length} file(s) to process');

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

  /// Checks if the current version (set by the build runner on the
  /// version.dart file) is the most recent one. If not, show a prompt to the
  /// user.
  Future<void> _checkForUpdates() async {
    try {
      final latestVersion = await _pubUpdater.getLatestVersion(packageName);
      final isUpToDate = packageVersion == latestVersion;
      if (!isUpToDate) {
        _logger
          ..info('')
          ..info('''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
Run ${lightCyan.wrap('$executableName update')} to update''');
      }
    } on Exception catch (_) {
      _logger.err('Failed to check for updates.');
    }
  }
}
