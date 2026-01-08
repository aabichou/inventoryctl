# Deployment Guide

## Prerequisites

Before deploying to PyPI, ensure you have:

1. **PyPI Account**: [https://pypi.org/](https://pypi.org/)
2. **GitHub Repository Settings**:
   - Configure trusted publishing on PyPI
   - Set up GitHub environments (optional but recommended)

## Setting Up Trusted Publishing (Recommended)

Trusted Publishing eliminates the need for API tokens. Set it up at:
https://pypi.org/manage/account/publishing/

### Steps:

1. Go to your PyPI account settings
2. Navigate to "Publishing" section
3. Add a new pending publisher with these details:
   - **PyPI Project Name**: `inventoryctl`
   - **Owner**: `aabichou` (your GitHub username)
   - **Repository name**: `inventoryctl`
   - **Workflow name**: `pypi-publish.yml`
   - **Environment name**: `pypi` (optional)

## Deployment Methods

### Method 1: Tag-based Release (Recommended)

```bash
# 1. Ensure version is bumped in pyproject.toml
git add pyproject.toml CHANGELOG.md
git commit -m "chore: bump version to 0.2.0"

# 2. Create and push a version tag
git tag v0.2.0
git push origin main
git push origin v0.2.0

# 3. GitHub Actions will automatically:
#    - Build the package
#    - Run checks
#    - Publish to PyPI
```

### Method 2: Manual Workflow Dispatch

1. Go to GitHub Actions tab
2. Select "Publish to PyPI" workflow
3. Click "Run workflow"
4. Optionally specify a version
5. Click "Run workflow" button

### Method 3: Local Publishing (Not Recommended)

```bash
# Install build tools
pip install build twine

# Build the package
python -m build

# Check the distribution
twine check dist/*

# Upload to TestPyPI (for testing)
twine upload --repository testpypi dist/*

# Upload to PyPI (production)
twine upload dist/*
```

## Verification

After deployment, verify the package:

```bash
# Install from PyPI
pip install --upgrade inventoryctl

# Check version
inventoryctl --version

# Verify new batch command exists
inventoryctl batch --help
```

## Troubleshooting

### "Package already exists"

- Version already published. Bump version in `pyproject.toml` and create a new
  tag

### "Trusted publishing not configured"

- Set up trusted publishing on PyPI as described above
- OR use API token method (not recommended)

### "Workflow doesn't have id-token: write permission"

- Permission is already configured in the workflow file
- Check repository settings if issues persist

## Docker Image Deployment

The Docker image is automatically built and published when:

- Pushing to `main`, `dev`, `staging`, or `prod` branches
- Creating version tags (`v*.*.*`)

Images are published to: `ghcr.io/aabichou/inventoryctl`

Tags:

- `latest` - main branch
- `dev`, `staging`, `prod` - respective branches
- `v0.2.0`, `0.2`, etc. - version tags

## Post-Deployment Checklist

- [ ] Verify package on PyPI: https://pypi.org/project/inventoryctl/
- [ ] Test installation: `pip install inventoryctl`
- [ ] Check Docker image: `docker pull ghcr.io/aabichou/inventoryctl:latest`
- [ ] Update documentation if needed
- [ ] Announce release (GitHub Releases, changelog, etc.)

## Release Workflow

```
┌─────────────────┐
│  Bump Version   │
│  in pyproject   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update CHANGELOG│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Git Commit     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Create Tag    │
│   git tag vX.Y.Z│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Push Tag      │
│   + Trigger CI  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  GitHub Actions │
│  Builds & Tests │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Publish to PyPI │
│  (Automatic)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Build Docker   │
│  Image (Auto)   │
└─────────────────┘
```
