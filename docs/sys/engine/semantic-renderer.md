---
generated: 2025-12-12T17:59:26Z
title: semantic_renderer.rb
source: lib/chiridion/engine/semantic_renderer.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/semantic_renderer.rb#L1
lines: 334
type: file
parent: engine
primary: Chiridion::Engine::SemanticRenderer
namespaces: [Chiridion::Engine::SemanticRenderer]
tags: [file, class]
description: Simplified semantic renderer that outputs structured data.
semantic-renderer-methods:
  - render(project)
  - render_index(project)
  - render_namespace(ns)
  - render_type_aliases(project)
  - SemanticRenderer.new(namespace_strip, project_title)
---

# Class: Chiridion::Engine::SemanticRenderer
**Extends:** Object

Simplified semantic renderer that outputs structured data.

Rather than formatting for human reading, this outputs all extracted
semantic data as JSON (or simple markdown with JSON payload). This helps:

1. Verify what data is being captured vs. missed
2. Debug the extraction pipeline
3. Provide machine-readable documentation for LLMs/agents
4. Separate concerns: extraction vs. presentation

Output format: YAML frontmatter + JSON code fence with all data.

## Attributes / Methods
`⟨render(…)              : Hash{String => String}⟩` — Render complete project documentation.
`⟨render_index(…)                                ⟩` — Render index page.
`⟨render_namespace(…)                            ⟩` — Render a namespace (class or module).
`⟨render_type_aliases(…)                         ⟩` — Render type aliases reference.

## Methods
### SemanticRenderer.new(...)
`⟨namespace_strip = nil                ⟩`
`⟨project_title   = "API Documentation"⟩`
⟶ `SemanticRenderer                    ` — A new instance of SemanticRenderer

#### Source
```ruby
# lib/chiridion/engine/semantic_renderer.rb:20
def initialize(namespace_strip: nil, project_title: "API Documentation")
  @namespace_strip = namespace_strip
  @project_title   = project_title
end
```

---
### render(...)
Render complete project documentation.

`⟨project : ProjectDoc   ⟩` — Complete documentation from SemanticExtractor
⟶ `Hash{String => String}` — Filename -> content mapping

---
### render_index(...)
Render index page.

`⟨project⟩`

---
### render_namespace(...)
Render a namespace (class or module).

`⟨ns⟩`

#### Source
```ruby
# lib/chiridion/engine/semantic_renderer.rb:89
def render_namespace(ns)
  frontmatter = build_frontmatter(ns)
  body_data   = build_body_data(ns)

  render_document(frontmatter, body_data)
end
```

---
### render_type_aliases(...)
Render type aliases reference.

`⟨project⟩`


---
**Private:** `#attribute_to_hash`:200, `#build_body_data`:125, `#build_frontmatter`:98, `#build_tags`:117, `#constant_to_hash`:183, `#example_to_hash`:170, `#ivar_to_hash`:192, `#method_summary`:283, `#method_to_hash`:250, `#namespace_to_filename`:319, `#option_to_hash`:219, `#overload_to_hash`:248, `#param_to_hash`:209, `#raise_to_hash`:246, `#render_document`:289, `#return_to_hash`:228, `#see_to_hash`:172, `#to_kebab_case`:326, `#type_alias_to_hash`:174, `#yield_to_hash`:234
