# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dart CLI tool called `fix_flutter_deprecations` that helps fix Flutter deprecations. The project is generated using Very Good CLI and follows Very Good Analysis standards.

## Development Commands

### Running the CLI
```bash
# Run the CLI locally
dart run bin/fix_deprecations.dart

# Run with specific commands
dart run bin/fix_deprecations.dart sample
dart run bin/fix_deprecations.dart sample --cyan
dart run bin/fix_deprecations.dart --version
dart run bin/fix_deprecations.dart --help
```

### Testing
```bash
# Run all tests
dart test

# Run tests with coverage
dart pub global activate coverage 1.2.0
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info

# Run specific test tag
dart test --tags version-verify

# Run tests matching a name pattern
dart test -n "test name pattern"
```

### Code Quality
```bash
# Run static analysis
dart analyze

# Format code
dart format .

# Check formatting without making changes
dart format --set-exit-if-changed .
```

### Build & Version Management
```bash
# Run build runner (generates version.dart)
dart run build_runner build

# Verify build
dart run build_verify
```

## Architecture

The project follows a standard Dart CLI application structure:

- **bin/fix_deprecations.dart**: Entry point that initializes the command runner
- **lib/src/command_runner.dart**: Main command runner that handles CLI arguments, version checking, and update functionality
- **lib/src/commands/**: Contains all CLI commands
  - `sample_command.dart`: Example command implementation
  - `update_command.dart`: Handles CLI self-updates via pub
- **lib/src/version.dart**: Generated file containing package version (do not edit manually)

The CLI uses:
- `args` package for command-line argument parsing
- `mason_logger` for styled console output
- `cli_completion` for shell completion support
- `pub_updater` for self-update functionality
- `very_good_analysis` for strict linting rules

## Key Implementation Details

- The executable name is `fix_deprecations` (not `fix_flutter_deprecations`)
- Version is managed through build_runner and stored in `lib/src/version.dart`
- The CLI supports automatic update checking and self-updating
- Uses Very Good Analysis which enforces strict Dart linting rules (except public_member_api_docs which is disabled)