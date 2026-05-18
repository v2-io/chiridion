# Changelog

## [0.3.4] - 2026-05-18

### Fixed
- Declare `logger` and `base64` as runtime dependencies. Both are Ruby
  default-gem extractions (`base64` @ 3.4, `logger` @ 3.5/4.0) that
  chiridion needs at runtime — `logger` directly (engine), `base64`
  transitively via `liquid` (which does not declare it). Without these,
  `require "chiridion"` raised `LoadError` for any consumer running
  under bundler on Ruby >= 3.4. No behavior change.

> Note: this changelog was not maintained for 0.2.x–0.3.3; entries
> resume here rather than reconstruct unrecorded history.

## [0.1.0] - 2024-12-09

### Added
- Initial release
- YARD-based documentation extraction
- RBS type signature integration
- Liquid template rendering
- Obsidian-compatible wikilinks
- Spec example extraction
- Drift detection for CI/CD
