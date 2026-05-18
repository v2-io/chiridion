# Changelog

## [0.3.5] - 2026-05-18

### Fixed

- **`Engine#check` now supports `:per_file` output mode.** `#refresh`
  branched on `output_mode` (per_file → `FileWriter`, mirroring source
  file paths) but `#check` did not — it always used the per-class
  `DriftChecker`, whose class-name kebab paths (`RefList` → `ref-list/`)
  do not match what the per_file writer actually produces (`reflist/`,
  from the source path). Result: every per_file doc was reported
  simultaneously "missing" and "orphaned". `#check` is now symmetric
  with `#refresh`; both build the per-file pipeline via one shared
  `build_per_file_pipeline`, and `FileWriter#check` reuses
  `FileWriter#output_path` — the divergence existed because path
  derivation was duplicated, so the fix removes the duplication. Drift
  semantics unchanged (warn + `exit 1` on drift, quiet otherwise).

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
