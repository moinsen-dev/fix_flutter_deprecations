# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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