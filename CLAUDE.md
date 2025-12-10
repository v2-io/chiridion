# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Chiridion (Greek χειρίδιον, "handbook") is an agent-oriented documentation generator for Ruby projects. It produces markdown optimized for AI agents and LLMs—structured frontmatter, explicit RBS types, Obsidian-compatible wikilinks—rather than traditional browser-focused docs.

## Commands

```bash
bundle install          # Install dependencies
toys test               # Run all tests
toys test test/foo.rb   # Run specific test file
toys cop                # Lint
toys cop --fix          # Lint with auto-fix
toys docs refresh       # Regenerate docs/sys/
gem build chiridion.gemspec  # Build gem
```

## Architecture

The system is a pipeline orchestrated by `Engine` (`lib/chiridion/engine.rb`):

```
Source Loading → Extraction → Type Merging → Rendering → Writing
```

### Pipeline Stages

1. **Source Loading** (`Engine#load_sources`)
   - YARD parses Ruby files, persists registry to `.yardoc/` for partial refresh
   - `InlineRbsLoader` extracts `@rbs` inline annotations (preferred)
   - `RbsLoader` loads `sig/*.rbs` files (fallback)
   - `RbsTypeAliasLoader` extracts type aliases from `sig/generated/`
   - `SpecExampleLoader` extracts RSpec examples (optional)

2. **Extraction** (`Extractor`)
   - Walks YARD registry for classes, modules, methods, constants
   - Filters by namespace prefix if configured
   - Supports partial refresh (single-file changes regenerate only affected docs)

3. **Type Merging** (`TypeMerger`)
   - **RBS is authoritative over YARD**—compile-time types override doc comments
   - Inline `@rbs` takes precedence over `sig/` files

4. **Rendering** (`Renderer` + Liquid templates in `templates/`)
   - Generates YAML frontmatter with navigation metadata
   - Creates `[[Wikilink]]` cross-references via `ClassLinker`
   - Adds GitHub source links via `GithubLinker`
   - Templates: `document.liquid` (class/module), `method.liquid`, `index.liquid`

5. **Writing** (`Writer` / `DriftChecker`)
   - Content-based change detection (only writes if content differs)
   - CI mode (`check`) detects drift without writing, exits 1 if out of sync

### Entry Points

- `Chiridion.configure` / `Chiridion.refresh` / `Chiridion.check` — convenience API in `lib/chiridion.rb`
- `Chiridion::Engine.new(...).refresh` — direct instantiation with explicit options
- `Chiridion::Config` — all configuration options with defaults

### Key Design Decisions

- **RBS Authority**: RBS types always win over YARD `@param`/`@return` types
- **Inline Preferred**: `@rbs` annotations in source are preferred over separate `sig/` files
- **YARD Registry Persistence**: `.yardoc/` enables efficient partial refresh
- **Obsidian-First Output**: Wikilinks, frontmatter tags, structured for vault consumption
- **Inline Source Display**: Methods with ≤10 body lines show their implementation inline (configurable via `inline_source_threshold`)
