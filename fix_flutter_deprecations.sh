#!/bin/bash

# Flutter Deprecation Fixer
# Simple and efficient script using Perl for text processing

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
CREATE_BACKUPS=false
DRY_RUN=false
VERBOSE=false
SELECTED_RULES=""

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Function to fix a single file
fix_file() {
    local file="$1"
    local temp_file="${file}.tmp"
    local changes_made=false
    
    print_verbose "Processing: $file"
    
    if [ "$DRY_RUN" = true ]; then
        # Check what would be changed
        local would_change=false
        
        if [[ -z "$SELECTED_RULES" ]] || [[ "$SELECTED_RULES" == *"withOpacity"* ]]; then
            if grep -q "\.withOpacity(" "$file"; then
                would_change=true
                print_info "[DRY RUN] Would fix withOpacity in: $file"
                grep -n "\.withOpacity(" "$file" | head -3
            fi
        fi
        
        if [[ -z "$SELECTED_RULES" ]] || [[ "$SELECTED_RULES" == *"surfaceVariant"* ]]; then
            if grep -q "\.surfaceVariant\b" "$file"; then
                would_change=true
                print_info "[DRY RUN] Would fix surfaceVariant in: $file"
                grep -n "\.surfaceVariant\b" "$file" | head -3
            fi
        fi
        
        return 0
    fi
    
    # Create backup if requested
    if [ "$CREATE_BACKUPS" = true ]; then
        cp "$file" "${file}.bak"
    fi
    
    # Apply fixes using Perl
    cp "$file" "$temp_file"
    
    # Fix withOpacity -> withValues(alpha: ...)
    if [[ -z "$SELECTED_RULES" ]] || [[ "$SELECTED_RULES" == *"withOpacity"* ]]; then
        perl -i -pe 's/\.withOpacity\s*\(\s*([^)]+)\s*\)/.withValues(alpha: $1)/g' "$temp_file"
    fi
    
    # Fix surfaceVariant -> surfaceContainerHighest
    if [[ -z "$SELECTED_RULES" ]] || [[ "$SELECTED_RULES" == *"surfaceVariant"* ]]; then
        perl -i -pe 's/\.surfaceVariant\b/.surfaceContainerHighest/g' "$temp_file"
    fi
    
    # Fix onSurfaceVariant -> onSurface (if needed)
    if [[ -z "$SELECTED_RULES" ]] || [[ "$SELECTED_RULES" == *"onSurfaceVariant"* ]]; then
        perl -i -pe 's/\.onSurfaceVariant\b/.onSurface/g' "$temp_file"
    fi
    
    # Check if changes were made
    if ! diff -q "$file" "$temp_file" > /dev/null; then
        changes_made=true
        mv "$temp_file" "$file"
        print_info "✓ Fixed: $file"
        
        if [ "$VERBOSE" = true ]; then
            # Show what was changed
            if [ "$CREATE_BACKUPS" = true ] && [ -f "${file}.bak" ]; then
                echo "  Changes:"
                diff -u "${file}.bak" "$file" | grep -E "^[+-]" | head -10
            fi
        fi
    else
        rm "$temp_file"
        print_verbose "  No changes needed"
    fi
    
    # Return status
    if [ "$changes_made" = true ]; then
        return 0
    else
        return 1
    fi
}

# Function to process all Dart files in a directory
process_directory() {
    local dir="${1:-.}"
    local total_files=0
    local fixed_files=0
    
    print_info "Searching for Dart files in: $dir"
    
    if [ -n "$SELECTED_RULES" ]; then
        print_info "Applying rules: $SELECTED_RULES"
    else
        print_info "Applying all deprecation rules"
    fi
    
    echo ""
    
    # Find all Dart files
    while IFS= read -r -d '' file; do
        ((total_files++))
        if fix_file "$file"; then
            ((fixed_files++))
        fi
    done < <(find "$dir" -name "*.dart" -type f ! -path "*/.dart_tool/*" ! -path "*/build/*" -print0)
    
    echo ""
    print_info "Summary:"
    print_info "  Total files scanned: $total_files"
    print_info "  Files fixed: $fixed_files"
    
    if [ "$fixed_files" -gt 0 ] && [ "$CREATE_BACKUPS" = true ]; then
        echo ""
        print_warning "Backup files created with .bak suffix"
        print_info "To remove all backups: find . -name '*.dart.bak' -delete"
    fi
}

# Function to validate changes
validate_changes() {
    local dir="${1:-.}"
    
    if command -v flutter > /dev/null 2>&1; then
        print_info "Running flutter analyze..."
        cd "$dir" && flutter analyze | grep -E "(deprecated|withOpacity|surfaceVariant)" | head -10 || echo "  No deprecation warnings found!"
    fi
}

# Function to list available rules
list_rules() {
    print_info "Available deprecation fix rules:"
    echo ""
    echo "  1. withOpacity       - Replace .withOpacity(value) with .withValues(alpha: value)"
    echo "  2. surfaceVariant    - Replace surfaceVariant with surfaceContainerHighest"
    echo "  3. onSurfaceVariant  - Replace onSurfaceVariant with onSurface"
    echo ""
    echo "Use -r flag to apply specific rules, e.g.: -r withOpacity,surfaceVariant"
}

# Show usage
usage() {
    cat << EOF
Flutter Deprecation Fixer

Usage: $0 [OPTIONS] [target]

Options:
  -b, --backup          Create backup files (.bak)
  -d, --dry-run         Show what would be changed without making changes
  -v, --verbose         Show detailed output
  -r, --rules RULES     Comma-separated list of rules to apply (default: all)
  -l, --list-rules      List all available deprecation rules
  -h, --help            Show this help message

Arguments:
  target                Path to file or directory (default: current directory)

Examples:
  $0                              # Fix all deprecations in current directory
  $0 -l                           # List available rules
  $0 -r withOpacity lib/          # Fix only withOpacity deprecations
  $0 -d -v lib/                   # Dry run with verbose output
  $0 -b path/to/file.dart         # Fix single file with backup

By default, NO backup files are created (assuming you use version control).
Use -b flag if you want backup files.

Supported deprecations:
  - withOpacity → withValues(alpha: ...)
  - surfaceVariant → surfaceContainerHighest
  - onSurfaceVariant → onSurface
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--backup)
            CREATE_BACKUPS=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -r|--rules)
            SELECTED_RULES="$2"
            shift 2
            ;;
        -l|--list-rules)
            list_rules
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

# Main execution
target="${1:-.}"

print_info "Flutter Deprecation Fixer"
print_info "========================"

if [ ! -e "$target" ]; then
    print_error "Target not found: $target"
    exit 1
fi

if [ -f "$target" ]; then
    # Single file mode
    fix_file "$target"
else
    # Directory mode
    process_directory "$target"
    
    if [ "$DRY_RUN" = false ]; then
        echo ""
        validate_changes "$target"
    fi
fi

echo ""
print_info "Done!"

if [ "$CREATE_BACKUPS" = false ] && [ "$DRY_RUN" = false ]; then
    print_info "No backup files were created. Use -b flag if you need backups."
fi