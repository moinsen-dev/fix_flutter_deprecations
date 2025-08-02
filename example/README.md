# Fix Flutter Deprecations - Example

This directory contains examples showing how to use the `fix_flutter_deprecations` tool.

## Running the Tool

### List available rules

```bash
# List all available deprecation fix rules
dart run fix_flutter_deprecations list

# List with detailed information
dart run fix_flutter_deprecations list --verbose
```

### Fix deprecations in a file

```bash
# Fix deprecations in a specific file
dart run fix_flutter_deprecations fix --path lib/my_file.dart

# Fix deprecations in entire project (current directory)
dart run fix_flutter_deprecations fix

# Preview changes without modifying files (dry run)
dart run fix_flutter_deprecations fix --dry-run

# Fix only specific rules
dart run fix_flutter_deprecations fix --rules withOpacity,surfaceVariant

# Fix without creating backups
dart run fix_flutter_deprecations fix --no-backup

# Show verbose output
dart run fix_flutter_deprecations fix --verbose
```

## Supported Deprecations

### 1. Color.withOpacity()

**Deprecated:**
```dart
Colors.blue.withOpacity(0.5)
```

**Fixed:**
```dart
Colors.blue.withValues(alpha: 0.5)
```

### 2. ColorScheme.surfaceVariant

**Deprecated:**
```dart
Theme.of(context).colorScheme.surfaceVariant
```

**Fixed:**
```dart
Theme.of(context).colorScheme.surfaceContainerHighest
```

### 3. ColorScheme.onSurfaceVariant

**Deprecated:**
```dart
Theme.of(context).colorScheme.onSurfaceVariant
```

**Fixed:**
```dart
Theme.of(context).colorScheme.onSurface
```

## Example Flutter Code

Here's an example of Flutter code with deprecations:

```dart
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      // Deprecated: surfaceVariant
      color: colorScheme.surfaceVariant,
      child: Text(
        'Hello',
        style: TextStyle(
          // Deprecated: onSurfaceVariant
          color: colorScheme.onSurfaceVariant,
          // Deprecated: withOpacity
          backgroundColor: Colors.blue.withOpacity(0.3),
        ),
      ),
    );
  }
}
```

After running `fix_flutter_deprecations fix`:

```dart
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      // Fixed: surfaceContainerHighest
      color: colorScheme.surfaceContainerHighest,
      child: Text(
        'Hello',
        style: TextStyle(
          // Fixed: onSurface
          color: colorScheme.onSurface,
          // Fixed: withValues
          backgroundColor: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
```

## Command Options

### fix command
- `--path` / `-p`: Path to file or directory to fix (default: current directory)
- `--dry-run` / `-d`: Preview changes without modifying files
- `--no-backup`: Skip creating backup files
- `--verbose` / `-v`: Show detailed output
- `--rules` / `-r`: Specific rules to apply (comma-separated)

### list command
- `--verbose` / `-v`: Show detailed information about each rule

## Safety Features

1. **Backup files**: By default, the tool creates `.backup` files before modifying
2. **Dry run mode**: Preview all changes before applying them
3. **Validation**: Each transformation is validated to ensure correctness
4. **Dart analysis**: Optionally runs `dart analyze` after fixes to verify code validity