# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-07-09

### Added
- nf-core migration and compliance updates
- Documentation
- Resource configuration profiles
- Standardized module structure
- Test framework setup

### Changed
- Restructured configuration files following nf-core standards
- FUNGuild container now uses internally patched `Guilds_v1.1.py` with explicit local database path support (`1.1+dada2nf.2`)

### Fixed

### Removed

## [0.1.0] - 2025-10-15

### Added
- Initial release
- Short-read DADA2 processing workflow
- Long-read DADA2 processing workflow
- Taxonomic classification with DECIPHER (short-read) and DADA2 (long-read)
- Read tracking and QC
- Support for guide tree construction
- PiCrust2 and FUNGuild functional prediction modules
- Singularity and Docker containerization

[Unreleased]: https://github.com/lschreib/DADA2-NF/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/lschreib/DADA2-NF/releases/tag/v0.2.0
[0.1.0]: https://github.com/lschreib/DADA2-NF/releases/tag/v0.1.0
