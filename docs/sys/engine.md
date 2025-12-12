---
generated: 2025-12-12T17:59:26Z
title: engine.rb
source: lib/chiridion/engine.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine.rb#L1
lines: 359
type: file
parent: chiridion
primary: Chiridion::Engine
namespaces: [Chiridion::DefaultLogger, Chiridion::Engine]
tags: [file, class]
description: Documentation engine for generating agent-oriented docs from Ruby source.
default-logger-methods: [error(msg), info(msg), warn(msg)]
engine-methods:
  - check
  - Engine.new(paths, output, namespace_filter, namespace_strip, include_specs, verbose, logger, root, rbs_path, spec_path, github_repo, github_branch, project_title, index_description, inline_source_threshold, output_mode)
  - refresh
  - refresh_per_file
---

# Class: Chiridion::DefaultLogger
**Extends:** Object

Simple default logger that prints to stderr.

## Attributes / Methods
`⟨error(…)⟩`
`⟨info(…) ⟩`
`⟨warn(…) ⟩`

## Methods
### error(...)
`⟨msg⟩`

#### Source
```ruby
# lib/chiridion/engine.rb:334
def error(msg) = Kernel.warn("ERROR: #{msg}")
```

---
### info(...)
`⟨msg⟩`

#### Source
```ruby
# lib/chiridion/engine.rb:332
def info(msg) = Kernel.warn(msg)
```

---
### warn(...)
`⟨msg⟩`

#### Source
```ruby
# lib/chiridion/engine.rb:333
def warn(msg) = Kernel.warn("WARNING: #{msg}")
```


---
# Class: Chiridion::Engine
**Extends:** Object

Documentation engine for generating agent-oriented docs from Ruby source.

Coordinates several specialized components:
- [[engine/extractor|Extractor]] - Walks YARD registry, extracts class/method/constant metadata
- [[engine/rbs-loader|RbsLoader]] - Loads RBS type signatures from sig/ directory
- [[engine/spec-example-loader|SpecExampleLoader]] - Extracts usage examples from RSpec files
- [[engine/type-merger|TypeMerger]] - Merges RBS types with YARD documentation
- [[engine/renderer|Renderer]] - Generates markdown with Obsidian-compatible wikilinks
- [[engine/writer|Writer]] - Handles file I/O with content-based change detection
- [[engine/drift-checker|DriftChecker]] - Detects when docs are out of sync with source

### YARD Registry Persistence
For performance, the engine persists YARD's parsed registry to .yardoc/.
This enables efficient partial refreshes: when a single file changes, we
load the existing registry, re-parse only that file, and regenerate only
the affected documentation.

### Example
**Generate docs via Engine**

```ruby
engine = Chiridion::Engine.new(
  paths: ['lib/myproject'],
  output: 'docs/sys',
  namespace_filter: 'MyProject::'
)
engine.refresh
```

**Partial refresh (single file)**

```ruby
engine = Chiridion::Engine.new(
  paths: ['lib/myproject/config.rb'],
  output: 'docs/sys',
  namespace_filter: 'MyProject::'
)
engine.refresh
```

## Attributes / Methods
`⟨output           : String       ⟩` — Output directory for generated docs
`⟨paths            : Array<String>⟩` — Source paths being documented
`⟨check                           ⟩` — Check for documentation drift without writing files.
`⟨refresh                         ⟩` — Generate documentation from source and write to output directory.
`⟨refresh_per_file                ⟩` — Generate per-file documentation using the semantic extraction pipeline.

## Methods
### check
Check for documentation drift without writing files.

⟶ `void`

Compares what would be generated against existing docs. Useful in CI
to ensure docs are kept in sync with source code changes.

**Raises:**
`SystemExit` — Exits with code 1 if drift is detected

#### Source
```ruby
# lib/chiridion/engine.rb:179
def check
  require "yard"
  register_rbs_tag

  @logger.info "Checking documentation drift for #{paths_description}..."

  load_sources
  doc_structure = extract_documentation(YARD::Registry)
  check_for_drift(doc_structure)
end
```

---
### Engine.new(...)
Create a new documentation engine.

`⟨paths                   : Array<String>               ⟩` — Source files or directories to document.
Can be specific files for partial refresh or directories for full refresh.
`⟨output                  : String                      ⟩` — Output directory for generated markdown docs.
`⟨namespace_filter        : String = nil                ⟩` — Only document classes starting with this prefix.
`⟨namespace_strip         : String = nil                ⟩` — Strip this prefix from output paths (defaults to namespace_filter).
`⟨include_specs           : Boolean = false             ⟩` — Whether to extract usage examples from spec files.
`⟨verbose                 : Boolean = false             ⟩` — Whether to show detailed progress and warnings.
`⟨logger                  : #info = nil                 ⟩` — Logger for output messages.
`⟨root                    : String = Dir.pwd            ⟩` — Project root directory for resolving relative paths.
`⟨rbs_path                : String = "sig"              ⟩` — Path to RBS signatures directory.
`⟨spec_path               : String = "test"             ⟩` — Path to spec directory.
`⟨github_repo             : String = nil                ⟩` — GitHub repository for source links.
`⟨github_branch           : String = "main"             ⟩` — Git branch for source links.
`⟨project_title           : String = "API Documentation"⟩` — Title for the documentation index.
`⟨index_description       : String = nil                ⟩` — Custom description for the index page.
`⟨inline_source_threshold : Integer = 10                ⟩` — Max body lines for inline source display.
`⟨output_mode             : :per_class = :per_class     ⟩` — Output organization strategy.
⟶ `Engine                                               ` — A new instance of Engine

---
### refresh
Generate documentation from source and write to output directory.

⟶ `void`

This is the main entry point for documentation generation. It:
1. Parses Ruby source files with YARD
2. Loads RBS type signatures
3. Extracts spec examples (if enabled)
4. Merges types with YARD docs
5. Renders to markdown with wikilinks
6. Writes files with content-based change detection

---
### refresh_per_file
Generate per-file documentation using the semantic extraction pipeline.

⟶ `void`

Produces one markdown file per source file, containing all namespaces
(classes/modules) defined in that file.


---
**Private:** `#check_for_drift`:299, `#extract_documentation`:266, `#find_rbs_generated_dir`:245, `#load_or_create_registry`:232, `#load_sources`:201, `#merge_rbs_types`:316, `#partial_refresh?`:230, `#paths_description`:192, `#register_rbs_tag`:195, `#resolve_ruby_files`:255, `#write_documentation`:282
