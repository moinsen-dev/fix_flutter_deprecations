import 'package:args/command_runner.dart';
import 'package:fix_flutter_deprecations/src/commands/commands.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('ListCommand', () {
    late MockLogger logger;
    late CommandRunner<int> commandRunner;

    setUp(() {
      logger = MockLogger();
      when(() => logger.info(any())).thenReturn(null);

      commandRunner = CommandRunner<int>('test', 'Test runner')
        ..addCommand(ListCommand(logger: logger));
    });

    group('command properties', () {
      test('has correct name and description', () {
        final command = ListCommand(logger: logger);
        expect(command.name, equals('list'));
        expect(command.description, contains('List available'));
      });
    });

    group('run', () {
      test('lists available rules', () async {
        final result = await commandRunner.run(['list']);

        expect(result, equals(ExitCode.success.code));
      });

      test('shows verbose output when requested', () async {
        final result = await commandRunner.run(['list', '--verbose']);

        expect(result, equals(ExitCode.success.code));
      });

      test('exits successfully', () async {
        final result = await commandRunner.run(['list']);

        expect(result, equals(ExitCode.success.code));
      });
    });
  });
}
