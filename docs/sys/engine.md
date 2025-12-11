---
generated: 2025-12-11T22:51:37Z
title: Chiridion::Engine
type: class
source: lib/chiridion/engine.rb:40
description: Documentation engine for generating agent-oriented docs from Ruby source.
inherits: Object
tags: [engine]
aliases: [Engine]
methods: [check, initialize, output, paths, refresh]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine.rb#L40
---

# Chiridion::Engine

Documentation engine for generating agent-oriented docs from Ruby source.

Coordinates several specialized components:
- [[engine/extractor|Extractor]] - Walks YARD registry, extracts class/method/constant metadata
- [[engine/rbs-loader|RbsLoader]] - Loads RBS type signatures from sig/ directory
- [[engine/spec-example-loader|SpecExampleLoader]] - Extracts usage examples from RSpec files
- [[engine/type-merger|TypeMerger]] - Merges RBS types with YARD documentation
- [[engine/renderer|Renderer]] - Generates markdown with Obsidian-compatible wikilinks
- [[engine/writer|Writer]] - Handles file I/O with content-based change detection
- [[engine/drift-checker|DriftChecker]] - Detects when docs are out of sync with source

## YARD Registry Persistence

For performance, the engine persists YARD's parsed registry to .yardoc/.
This enables efficient partial refreshes: when a single file changes, we
load the existing registry, re-parse only that file, and regenerate only
the affected documentation.

## Example

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





## Attributes

`⟨output : String⟩       ` — (Read) Output directory for generated docs
`⟨paths  : Array<String>⟩` — (Read) Source paths being documented

## Methods

### Engine.new(...)
Create a new documentation engine.

`⟨paths                  ⟩                      `
`⟨output                 ⟩                      `
`⟨namespace_filter        = nil⟩                `
`⟨namespace_strip         = nil⟩                `
`⟨include_specs           = false⟩              `
`⟨verbose                 = false⟩              `
`⟨logger                  = nil⟩                `
`⟨root                    = Dir.pwd⟩            `
`⟨rbs_path                = "sig"⟩              `
`⟨spec_path               = "test"⟩             `
`⟨github_repo             = nil⟩                `
`⟨github_branch           = "main"⟩             `
`⟨project_title           = "API Documentation"⟩`
`⟨index_description       = nil⟩                `
`⟨inline_source_threshold = 10⟩                 `
⟶ `Engine                                       ` — A new instance of Engine


---
### refresh
Generate documentation from source and write to output directory.

This is the main entry point for documentation generation. It:
1. Parses Ruby source files with YARD
2. Loads RBS type signatures
3. Extracts spec examples (if enabled)
4. Merges types with YARD docs
5. Renders to markdown with wikilinks
6. Writes files with content-based change detection

```ruby
# lib/chiridion/engine.rb : ~110
def refresh
  require "yard"
  register_rbs_tag

  @logger.info "Parsing Ruby files in #{paths_description}..."

  load_sources
  doc_structure = extract_documentation(YARD::Registry)
  write_documentation(doc_structure)
  @logger.info "Documentation written to #{@output}/"
end
```


---
### check
Check for documentation drift without writing files.

Compares what would be generated against existing docs. Useful in CI
to ensure docs are kept in sync with source code changes.

```ruby
# lib/chiridion/engine.rb : ~129
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

**Private:** `#check_for_drift`:248, `#extract_documentation`:216, `#find_rbs_generated_dir`:195, `#load_or_create_registry`:182, `#load_sources`:151, `#merge_rbs_types`:265, `#partial_refresh?`:180, `#paths_description`:142, `#register_rbs_tag`:145, `#resolve_ruby_files`:205, `#write_documentation`:232
