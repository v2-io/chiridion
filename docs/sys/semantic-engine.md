---
generated: 2025-12-12T17:59:26Z
title: semantic_engine.rb
source: lib/chiridion/semantic_engine.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/semantic_engine.rb#L1
lines: 186
type: file
parent: chiridion
primary: Chiridion::SemanticEngine
namespaces: [Chiridion::SemanticEngine]
tags: [file, class]
description: Semantic documentation engine - outputs structured JSON data.
semantic-engine-methods:
  - refresh
  - SemanticEngine.new(paths, output, namespace_filter, namespace_strip, include_specs, verbose, logger, root, rbs_path, spec_path, project_title, project_description)
---

# Class: Chiridion::SemanticEngine
**Extends:** Object

Semantic documentation engine - outputs structured JSON data.

This is an alternative to the regular Engine that focuses on semantic
extraction and outputs machine-readable JSON alongside markdown. It's
useful for:

- Verifying what data is being captured
- Debugging the extraction pipeline
- Generating LLM-friendly documentation
- Separating extraction from presentation

Usage:
  engine = Chiridion::SemanticEngine.new(
    paths: ['lib/myproject'],
    output: 'docs/sys',
    namespace_filter: 'MyProject::'
  )
  engine.refresh

## Attributes / Methods
`⟨output ⟩` — (Read)
`⟨paths  ⟩` — (Read)
`⟨refresh⟩`

## Methods
### SemanticEngine.new(...)
`⟨paths                                    ⟩`
`⟨output                                   ⟩`
`⟨namespace_filter    = nil                ⟩`
`⟨namespace_strip     = nil                ⟩`
`⟨include_specs       = false              ⟩`
`⟨verbose             = false              ⟩`
`⟨logger              = nil                ⟩`
`⟨root                = Dir.pwd            ⟩`
`⟨rbs_path            = "sig"              ⟩`
`⟨spec_path           = "test"             ⟩`
`⟨project_title       = "API Documentation"⟩`
`⟨project_description = nil                ⟩`
⟶ `SemanticEngine                          ` — A new instance of SemanticEngine

---
### refresh
---
**Private:** `#extract_documentation`:132, `#find_rbs_generated_dir`:111, `#load_sources`:88, `#paths_description`:80, `#register_rbs_tag`:82, `#render_documentation`:150, `#resolve_ruby_files`:121, `#write_files`:159
