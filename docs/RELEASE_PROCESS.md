# Release Process

This document describes how to create releases for the `fix_flutter_deprecations` project.

## Automated Release Workflow

The project uses GitHub Actions to automatically create releases and publish to pub.dev when a version tag is pushed.

## Prerequisites

Before creating a release, ensure:

1. You are on the `develop` branch
2. All changes are committed and pushed
3. All tests pass (`make test`)
4. Code analysis passes (`make analyze`)
5. Code is properly formatted (`make format-check`)
6. CHANGELOG.md has been updated with the new changes under `## [Unreleased]`

## Release Steps

### Option 1: Using the Release Script (Recommended)

The easiest way to create a release is using the automated release script:

```bash
# Interactive mode - script will ask for version
make release-interactive

# Or specify version directly
make release VERSION=0.1.3
```

The script will:
1. ✅ Verify you're on the `develop` branch
2. ✅ Check that working directory is clean
3. ✅ Pull latest changes
4. ✅ Update `pubspec.yaml` with new version
5. ✅ Move unreleased items in `CHANGELOG.md` to the new version
6. ✅ Regenerate `lib/src/version.dart`
7. ✅ Run tests to ensure everything works
8. ✅ Commit the version bump
9. ✅ Create and push a git tag
10. ✅ Trigger the GitHub Actions release workflow

### Option 2: Manual Process

If you prefer to do it manually:

1. **Update version in `pubspec.yaml`**:
   ```yaml
   version: 0.1.3
   ```

2. **Update `CHANGELOG.md`**:
   - Move items from `## [Unreleased]` to `## [0.1.3] - 2025-08-03`
   - Add the new version link at the bottom

3. **Regenerate version file**:
   ```bash
   dart run build_runner build
   ```

4. **Run tests**:
   ```bash
   make test
   ```

5. **Commit changes**:
   ```bash
   git add pubspec.yaml CHANGELOG.md lib/src/version.dart
   git commit -m "chore: bump version to 0.1.3"
   ```

6. **Create and push tag**:
   ```bash
   git tag -a v0.1.3 -m "Release version 0.1.3"
   git push origin develop
   git push origin v0.1.3
   ```

## GitHub Actions Workflow

When a tag matching `v*.*.*` is pushed, the release workflow automatically:

### 🧪 **Build and Test Job**
- Checks out the code
- Sets up Dart environment
- Installs dependencies
- Runs all tests with coverage
- Validates code coverage (minimum 95%)
- Runs static analysis
- Checks code formatting
- Verifies version consistency

### 📦 **Create GitHub Release Job**
- Extracts version from git tag
- Extracts changelog for the version
- Creates a GitHub release with:
  - Release notes from CHANGELOG.md
  - Installation instructions
  - Usage examples
  - Links to full changelog

### 🚀 **Publish to pub.dev Job**
- Builds the package
- Runs dry-run validation
- Publishes to pub.dev

## Monitoring Releases

After pushing a tag, you can monitor the release process at:
- **GitHub Actions**: https://github.com/moinsen-dev/fix_flutter_deprecations/actions
- **Releases**: https://github.com/moinsen-dev/fix_flutter_deprecations/releases
- **pub.dev**: https://pub.dev/packages/fix_flutter_deprecations

## Release Checklist

Before creating a release:

- [ ] All features for the release are complete
- [ ] All tests pass (`make test`)
- [ ] Code analysis passes (`make analyze`)
- [ ] Code is formatted (`make format-check`)
- [ ] CHANGELOG.md is updated with new features/fixes
- [ ] Version follows semantic versioning (MAJOR.MINOR.PATCH)
- [ ] On `develop` branch with latest changes

After release:

- [ ] GitHub release is created successfully
- [ ] Package is published to pub.dev
- [ ] Release notes are accurate
- [ ] Installation works: `dart pub global activate fix_flutter_deprecations`

## Troubleshooting

### Tag Already Exists
If you see "Tag vX.Y.Z already exists":
```bash
# Delete the tag locally and remotely
git tag -d vX.Y.Z
git push origin :refs/tags/vX.Y.Z

# Then try the release again
```

### GitHub Actions Fails
Check the workflow logs at:
https://github.com/moinsen-dev/fix_flutter_deprecations/actions

Common issues:
- Test failures: Fix failing tests and retag
- Coverage too low: Add more tests to reach 95% coverage
- Analysis errors: Fix linting issues and retag
- Pub.dev publish fails: Check for package validation errors

### pub.dev Publishing Fails
The workflow uses OpenID Connect (OIDC) for publishing. If publishing fails:
1. Check that the repository has the correct pub.dev publisher permissions
2. Verify the package follows pub.dev guidelines
3. Ensure no breaking changes without major version bump

## Versioning Strategy

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version (X.0.0): Breaking changes
- **MINOR** version (0.X.0): New features, backwards compatible
- **PATCH** version (0.0.X): Bug fixes, backwards compatible

### Examples:
- `0.1.2` → `0.1.3`: Bug fix
- `0.1.3` → `0.2.0`: New deprecation rule added
- `0.2.0` → `1.0.0`: Breaking API changes