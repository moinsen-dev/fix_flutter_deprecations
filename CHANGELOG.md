# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-05-04

### Added
- **9 new lint-fix rules** that complement `dart fix` for `very_good_analysis`-style projects:
  - `cascadeInvocations`: collapse runs of `obj.a(); obj.b(); obj.c();` into a cascade chain. Skips capitalized receivers (static calls on classes) and any run that contains an assignment.
  - `controlBodyNewLine`: rewrite inline `if (x) y;` / `for (...)` / `while (...)` to a braced 3-line form, satisfying both `always_put_control_body_on_new_line` and `curly_braces_in_flow_control_structures`.
  - `avoidPrint`: insert a documented `// ignore: avoid_print` above any unguarded `print(...)` call. Skips files with a file-level `// ignore_for_file: avoid_print` directive and ignores `print` mentions inside string literals or comments.
  - `flutterStyleTodos`: rewrite unnamed `// TODO:` (and `/// TODO:`) comments to the Flutter `// TODO(unassigned):` style.
  - `unintendedHtmlDocComment`: wrap `<Type>` style fragments inside `///` doc comments in backticks. Allowed HTML tags (`<br>`, `<p>`, `<a>`, `<code>`, ...) are left alone.
  - `unreachableFromMain`: heuristically tag top-level test helpers (functions whose names contain `mock`, `setup`, `helper`, `seed`, `fixture`, `stub`, or `fake`) with `// ignore: unreachable_from_main`.
  - `strictRawType`: replace `Map<dynamic, dynamic>` with `Map<String, dynamic>`.
  - `removedLint`: remove retired lint names (e.g. `package_api_docs`, `iterable_contains_unrelated_type`, ...) from `analysis_options.yaml`.
  - `sortPubDependencies`: alphabetically sort `dependencies:`, `dev_dependencies:` and `dependency_overrides:` blocks in `pubspec.yaml` while preserving comments and multi-line entries.
- **YAML support**: rules can now declare `appliesToExtensions` to target project-config files (`pubspec.yaml`, `analysis_options.yaml`) in addition to `.dart` source files. The CLI scans config files at the project root automatically.
- **Generated-area exclusion**: `.dart_tool/`, `build/`, `.fvm/` directories are skipped during traversal.

### Fixed
- `--help` / `-h` now prints usage instead of starting to process files.

### Changed
- `FileUtils.findDartFiles` now delegates to `FileUtils.findProjectFiles`, which accepts an extension set and a `includeProjectConfigs` flag.
- `FileProcessor` filters rules per-file based on `appliesToExtensions`, so yaml-only rules never run on Dart files and vice versa.

## [0.1.2] - 2025-08-03

### Added
- **WillPopScope to PopScope Migration**: Automatically converts deprecated `WillPopScope` widgets to `PopScope` with intelligent callback transformation
  - Handles simple boolean returns by converting to `canPop` property
  - Transforms complex logic into `onPopInvoked` callbacks with proper navigation handling
- **Multiple Underscores Lint Fix**: Automatically fixes "unnecessary use of multiple underscores" warnings
  - Intelligently preserves generated code patterns and test mocks
  - Converts multiple underscores to single underscores where appropriate
- **BuildContext Async Safety**: Fixes `use_build_context_synchronously` lint warnings by adding mounted checks
  - Automatically detects BuildContext usage after async operations
  - Adds appropriate mounted checks (`if (mounted)` for StatefulWidget, `if (context.mounted)` for others)
  - Supports Navigator, showDialog, ScaffoldMessenger, Theme, and MediaQuery operations
  - Maintains proper code indentation and formatting

### Enhanced
- Extended rule registry to support 6 total deprecation rules
- Improved pattern matching with more sophisticated regex handling
- Enhanced validation logic for complex code transformations

## [0.1.1] - 2025-08-02

### Fixed
- Fixed broken images in README on pub.dev by correcting GitHub repository URLs
- Updated coverage badge to use repository-hosted SVG file

### Changed
- Added proper attribution footer with credits to Claude Code and Moinsen Development

## [0.1.0] - 2025-08-02

### Added
- Initial release of fix_flutter_deprecations CLI tool
- Support for fixing `.withOpacity()` to `.withValues(alpha:)` deprecation
- Support for fixing `surfaceVariant` to `surfaceContainerHighest` deprecation  
- Support for fixing `onSurfaceVariant` to `onSurface` deprecation
- Dry-run mode to preview changes before applying
- Backup functionality for safe operation
- Selective rule application
- Progress tracking and detailed reporting
- Extensible architecture for adding new deprecation rules
- Comprehensive test coverage (100%)
- Full compatibility with Very Good Analysis standards

### Features
- Process single files or entire directories
- Parallel file processing for performance
- Detailed error reporting and recovery
- Platform support for Windows, macOS, and Linux

[Unreleased]: https://github.com/moinsen-dev/fix_flutter_deprecations/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/moinsen-dev/fix_flutter_deprecations/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/moinsen-dev/fix_flutter_deprecations/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/moinsen-dev/fix_flutter_deprecations/releases/tag/v0.1.0