---
generated: 2025-12-10T22:33:19Z
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





## Methods

### paths

→ Array[String] — Source paths being documented


```ruby
def paths
  @paths
end
```


---
### output

→ String — Output directory for generated docs


```ruby
def output
  @output
end
```


---
### Engine.new(...)
*Create a new documentation engine.*

⟨paths                   : untyped⟩
⟨output                  : untyped⟩
⟨namespace_filter        : untyped = nil⟩
⟨namespace_strip         : untyped = nil⟩
⟨include_specs           : untyped = false⟩
⟨verbose                 : untyped = false⟩
⟨logger                  : untyped = nil⟩
⟨root                    : untyped = Dir.pwd⟩
⟨rbs_path                : untyped = "sig"⟩
⟨spec_path               : untyped = "test"⟩
⟨github_repo             : untyped = nil⟩
⟨github_branch           : untyped = "main"⟩
⟨project_title           : untyped = "API Documentation"⟩
⟨index_description       : untyped = nil⟩
⟨inline_source_threshold : untyped = 10⟩
→ Engine — a new instance of Engine


---
### refresh
*Generate documentation from source and write to output directory.

This is the main entry point for documentation generation. It:
1. Parses Ruby source files with YARD
2. Loads RBS type signatures
3. Extracts spec examples (if enabled)
4. Merges types with YARD docs
5. Renders to markdown with wikilinks
6. Writes files with content-based change detection*

```ruby
def refresh
  require "yard"

  @logger.info "Parsing Ruby files in #{paths_description}..."

  load_sources
  doc_structure = extract_documentation(YARD::Registry)
  write_documentation(doc_structure)
  @logger.info "Documentation written to #{@output}/"
end
```


---
### check
*Check for documentation drift without writing files.

Compares what would be generated against existing docs. Useful in CI
to ensure docs are kept in sync with source code changes.*

```ruby
def check
  require "yard"

  @logger.info "Checking documentation drift for #{paths_description}..."

  load_sources
  doc_structure = extract_documentation(YARD::Registry)
  check_for_drift(doc_structure)
end
```
