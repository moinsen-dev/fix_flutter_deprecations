# Fix Flutter Deprecations

<p align="center">
  <img src="https://raw.githubusercontent.com/moinsen-dev/fix_flutter_deprecations/main/images/fix_deprecations_logo.png" alt="Fix Flutter Deprecations Logo" width="200"/>
</p>

<p align="center">
  <a href="https://github.com/udimain/fix_flutter_deprecations/actions"><img src="https://github.com/udimain/fix_flutter_deprecations/actions/workflows/main.yaml/badge.svg" alt="ci"></a>
  <a href="https://codecov.io/gh/udimain/fix_flutter_deprecations"><img src="https://codecov.io/gh/udimain/fix_flutter_deprecations/branch/main/graph/badge.svg" alt="coverage"></a>
  <a href="https://pub.dev/packages/very_good_analysis"><img src="https://img.shields.io/badge/style-very_good_analysis-B22C89.svg" alt="style: very good analysis"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

A powerful and extensible Dart command-line tool that automatically fixes Flutter deprecations in your codebase. As Flutter evolves, APIs get deprecated and replaced with new ones. This tool helps you migrate your codebase efficiently by automatically applying common deprecation fixes.

<p align="center">
  <img src="https://raw.githubusercontent.com/moinsen-dev/fix_flutter_deprecations/main/images/fix_deprecations_wallpaper.png" alt="Fix Flutter Deprecations in action" width="800"/>
</p>

## Features ✨

- **Automatic Deprecation Fixes**: Automatically updates deprecated Flutter APIs to their modern equivalents
- **Extensible Architecture**: Easily add new deprecation rules as Flutter evolves
- **Safe Operation**: Dry-run mode to preview changes before applying them
- **Selective Fixes**: Apply specific deprecation fixes or all at once
- **Progress Tracking**: Clear feedback on what's being changed
- **Backup Support**: Optional backup creation before making changes

## Currently Supported Deprecations

| Deprecated API | Replacement | Flutter Version |
|----------------|-------------|-----------------|
| `.withOpacity(value)` | `.withValues(alpha: value)` | 3.27+ |
| `surfaceVariant` | `surfaceContainerHighest` | Material 3 |
| `onSurfaceVariant` | `onSurface` | Material 3 |

## Installation 📦

### Global Installation

```sh
dart pub global activate fix_flutter_deprecations
```

### Local Development

```sh
dart pub global activate --source=path .
```

## Usage 🚀

### Fix all deprecations in your project

```sh
fix_deprecations
```

### Preview changes without applying them (dry run)

```sh
fix_deprecations --dry-run
```

### Apply specific deprecation fixes

```sh
fix_deprecations --rules withOpacity,surfaceVariant
```

### Fix a specific file or directory

```sh
fix_deprecations lib/src/widgets/
fix_deprecations lib/main.dart
```

### Create backups before fixing

```sh
fix_deprecations --backup
```

### List all available deprecation rules

```sh
fix_deprecations list
```

## Command Reference

```sh
# Fix all deprecations in current directory
fix_deprecations fix

# Fix with specific options
fix_deprecations fix --dry-run --verbose
fix_deprecations fix --rules withOpacity --backup lib/

# List available deprecation rules
fix_deprecations list

# Show version
fix_deprecations --version

# Show help
fix_deprecations --help
```

## Running Tests with coverage 🧪

To run all unit tests use the following command:

```sh
$ dart pub global activate coverage 1.2.0
$ dart test --coverage=coverage
$ dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov)
.

```sh
# Generate Coverage Report
$ genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
$ open coverage/index.html
```

## Adding New Deprecation Rules 🔧

The tool is designed to be easily extensible. To add a new deprecation rule:

1. Create a new rule class in `lib/src/rules/`
2. Implement the `DeprecationRule` interface
3. Register the rule in the rule registry

Example:
```dart
class MyDeprecationRule extends DeprecationRule {
  @override
  String get name => 'myDeprecation';
  
  @override
  String get description => 'Fixes MyOldAPI to MyNewAPI';
  
  @override
  String apply(String content) {
    // Implementation here
  }
}
```

## Architecture 🏗️

The project follows a clean, extensible architecture:

- **Commands**: CLI commands for different operations (fix, list, etc.)
- **Rules**: Individual deprecation fix implementations
- **Processors**: File processing and transformation logic
- **Utils**: Shared utilities for file operations, logging, etc.

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Adding a new deprecation fix:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/new-deprecation-fix`)
3. Add your deprecation rule with tests
4. Ensure all tests pass and code follows Very Good Analysis standards
5. Commit your changes (`git commit -m 'Add new deprecation fix for XYZ'`)
6. Push to the branch (`git push origin feature/new-deprecation-fix`)
7. Open a Pull Request

---

Generated with 💙 by [Very Good CLI][very_good_cli_link]

[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli