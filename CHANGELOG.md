# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-01-08

### Added

- **Native JSON Batch Operations**: New `batch` command for processing multiple
  operations in a single CLI call
  - `inventoryctl batch host <action>` - Batch operations for hosts (add,
    update, delete)
  - `inventoryctl batch group <action>` - Batch operations for groups
  - Supports both file input (`--file`) and stdin
  - Eliminates dependency on external tools like `jq` in CI/CD pipelines
  - Provides detailed per-item feedback with summary statistics
  - Proper exit codes: 0 (success), 1 (all failed), 2 (partial success)
  - Auto-creates groups if they don't exist during host operations

### Changed

- CI/CD pipelines can now use native batch command instead of complex shell
  loops
- Simplified GitLab CI example using the new batch feature

### Documentation

- Added batch command examples to README
- Created GitLab CI batch example documentation
- Added migration guide from jq-based approach to native batch command

## [0.1.3] - Previous Release

### Features

- CRUD operations for hosts and groups
- Bulk sync operations
- Validation and formatting
- Rendering to Ansible inventory and SSH config
- Metadata support with `_meta` tags
