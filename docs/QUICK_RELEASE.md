# Quick Release Reference

## 🚀 Create a New Release

### Interactive Mode (Recommended)
```bash
make release-interactive
```

### Direct Version
```bash
make release VERSION=0.1.3
```

## 🔍 Check Release Status

### Check Current Version
```bash
make current-version
```

### Check if Current Version is Tagged
```bash
make tag-check
```

### Monitor Release Progress
- **GitHub Actions**: https://github.com/moinsen-dev/fix_flutter_deprecations/actions
- **Releases**: https://github.com/moinsen-dev/fix_flutter_deprecations/releases

## 📋 Pre-Release Checklist

```bash
# Run all checks
make verify

# Check current version
make current-version

# Check if tag exists
make tag-check
```

## 🎯 What the Release Does

1. ✅ Updates `pubspec.yaml` version
2. ✅ Updates `CHANGELOG.md`
3. ✅ Regenerates `lib/src/version.dart`
4. ✅ Runs tests
5. ✅ Commits changes
6. ✅ Creates git tag
7. ✅ Pushes to GitHub
8. ✅ Triggers automated GitHub release
9. ✅ Publishes to pub.dev

## 🛠️ Manual Tag Creation (if needed)

```bash
# Create tag
git tag -a v0.1.3 -m "Release version 0.1.3"

# Push tag
git push origin v0.1.3
```

## 🔧 Troubleshooting

### Delete Tag (if needed)
```bash
# Delete locally
git tag -d v0.1.3

# Delete remotely  
git push origin :refs/tags/v0.1.3
```

### Force Release (if tag exists)
```bash
# Delete existing tag first, then release again
git tag -d v0.1.3
git push origin :refs/tags/v0.1.3
make release VERSION=0.1.3
```