import 'package:args/command_runner.dart';
import 'package:fix_flutter_deprecations/src/rules/rules.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template list_command}
/// Command to list all available deprecation fix rules.
/// {@endtemplate}
class ListCommand extends Command<int> {
  /// {@macro list_command}
  ListCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed information about each rule',
      negatable: false,
    );
  }

  final Logger _logger;

  @override
  String get description => 'List all available deprecation fix rules';

  @override
  String get name => 'list';

  @override
  Future<int> run() async {
    final verbose = argResults!['verbose'] as bool;

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
        '${lightCyan.wrap('fix_deprecations fix --rules rule1,rule2')}',
      );

    return ExitCode.success.code;
  }
}
