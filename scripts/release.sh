#!/bin/bash

# Release script for fix_flutter_deprecations
# This script helps create a new release by tagging the current commit

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're on the develop branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "develop" ]; then
    print_error "You must be on the 'develop' branch to create a release"
    print_info "Current branch: $current_branch"
    exit 1
fi

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    print_error "Working directory is not clean. Please commit or stash your changes."
    git status --short
    exit 1
fi

# Pull latest changes
print_info "Pulling latest changes from origin/develop..."
git pull origin develop

# Get current version from pubspec.yaml
current_version=$(grep '^version:' pubspec.yaml | sed 's/version: //')
print_info "Current version: $current_version"

# Ask for new version if not provided
if [ -z "$1" ]; then
    echo
    print_info "Enter the new version (current: $current_version):"
    read -r new_version
else
    new_version="$1"
fi

# Validate version format (basic semantic versioning)
if ! [[ $new_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format. Please use semantic versioning (e.g., 1.0.0)"
    exit 1
fi

# Check if tag already exists
if git tag -l | grep -q "^v$new_version$"; then
    print_error "Tag v$new_version already exists"
    exit 1
fi

print_info "Preparing release v$new_version..."

# Update version in pubspec.yaml
print_info "Updating pubspec.yaml..."
sed -i.bak "s/^version: .*/version: $new_version/" pubspec.yaml
rm pubspec.yaml.bak

# Update CHANGELOG.md - move unreleased items to new version
print_info "Updating CHANGELOG.md..."
today=$(date '+%Y-%m-%d')

# Create a temporary file with the updated changelog
temp_changelog=$(mktemp)

# Process the changelog
awk -v version="$new_version" -v date="$today" '
    /^## \[Unreleased\]/ {
        print $0
        print ""
        print "## [" version "] - " date
        next
    }
    { print }
' CHANGELOG.md > "$temp_changelog"

# Replace the original file
mv "$temp_changelog" CHANGELOG.md

# Update version links at the bottom
sed -i.bak "s|\[Unreleased\]: .*/compare/v.*\.\.\.HEAD|[Unreleased]: https://github.com/moinsen-dev/fix_flutter_deprecations/compare/v$new_version...HEAD|" CHANGELOG.md
sed -i.bak "/\[Unreleased\]: /a\\
[$new_version]: https://github.com/moinsen-dev/fix_flutter_deprecations/compare/v$current_version...v$new_version" CHANGELOG.md
rm CHANGELOG.md.bak

# Regenerate version.dart
print_info "Regenerating version.dart..."
dart run build_runner build

# Run tests to make sure everything works
print_info "Running tests..."
dart test

# Commit version bump
print_info "Committing version bump..."
git add pubspec.yaml CHANGELOG.md lib/src/version.dart
git commit -m "chore: bump version to $new_version

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Create and push tag
print_info "Creating tag v$new_version..."
git tag -a "v$new_version" -m "Release version $new_version

See CHANGELOG.md for details.

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push changes and tag
print_info "Pushing changes and tag to origin..."
git push origin develop
git push origin "v$new_version"

print_success "Release v$new_version created successfully!"
print_info "The GitHub Actions workflow will now:"
print_info "  1. Run tests and checks"
print_info "  2. Create a GitHub release"
print_info "  3. Publish to pub.dev"
print_info ""
print_info "You can monitor the progress at:"
print_info "  https://github.com/moinsen-dev/fix_flutter_deprecations/actions"
print_info ""
print_info "The release will be available at:"
print_info "  https://github.com/moinsen-dev/fix_flutter_deprecations/releases/tag/v$new_version"