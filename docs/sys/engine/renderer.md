---
generated: 2025-12-10T22:33:19Z
title: Chiridion::Engine::Renderer
type: class
source: lib/chiridion/engine/renderer.rb:22
description: Renders documentation to Obsidian-compatible markdown.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, renderer]
aliases: [Renderer]
methods: [initialize, register_classes, render_class, render_index, render_module, render_type_aliases]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/renderer.rb#L22
---

# Chiridion::Engine::Renderer

Renders documentation to Obsidian-compatible markdown.

Uses Liquid templates for the document body content, while YAML frontmatter
is rendered directly in Ruby due to its complex formatting requirements
(flow vs block arrays, proper quoting, etc.).

## Template Customization

Templates are loaded from the gem's templates/ directory by default.
Override by passing a custom templates_path to the constructor.

## Enhanced Frontmatter

All generated documents include enhanced YAML frontmatter for Obsidian:
- **Navigation**: parent links for breadcrumb traversal
- **Discovery**: tags for filtering, related links for exploration
- **Search**: aliases for finding by short name, description for preview





## Methods

### Renderer.new(...)

⟨namespace_strip         : untyped⟩
⟨include_specs           : untyped⟩
⟨root                    : untyped = Dir.pwd⟩
⟨github_repo             : untyped = nil⟩
⟨github_branch           : untyped = "main"⟩
⟨project_title           : untyped = "API Documentation"⟩
⟨index_description       : untyped = nil⟩
⟨templates_path          : untyped = nil⟩
⟨inline_source_threshold : untyped = 10⟩
→ Renderer — a new instance of Renderer


---
### register_classes(...)
*Register known classes for cross-reference linking and inheritance.*

⟨structure : Hash⟩ → Documentation structure from Extractor


```ruby
def register_classes(structure)
  @class_linker.register_classes(structure)
  @frontmatter_builder.register_inheritance(structure)
end
```


---
### render_index(...)
*Render the documentation index.*

⟨structure : Hash⟩ → Documentation structure from Extractor
→ String — Markdown index


---
### render_class(...)
*Render class documentation.*

⟨klass : Hash⟩ → Class data from Extractor
→ String — Markdown documentation


```ruby
def render_class(klass) = render_document(klass, include_mixins: true)
```


---
### render_module(...)
*Render module documentation.*

⟨mod : Hash⟩ → Module data from Extractor
→ String — Markdown documentation


```ruby
def render_module(mod) = render_document(mod, include_mixins: false)
```


---
### render_type_aliases(...)
*Render type aliases reference page.*

⟨type_aliases : Hash{String =] Array[Hash]}⟩ → namespace -> types mapping
→ String — Markdown documentation
