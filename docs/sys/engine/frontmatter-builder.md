---
generated: 2025-12-10T22:33:19Z
title: Chiridion::Engine::FrontmatterBuilder
type: class
source: lib/chiridion/engine/frontmatter_builder.rb:16
description: Builds enhanced YAML frontmatter for documentation files.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, frontmatter-builder]
aliases: [FrontmatterBuilder]
methods: [build, build_index, initialize, register_inheritance]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/frontmatter_builder.rb#L16
---

# Chiridion::Engine::FrontmatterBuilder

Builds enhanced YAML frontmatter for documentation files.

Generates Obsidian-compatible frontmatter with navigation aids,
discovery metadata, and search-friendly fields. Each documentation
file gets frontmatter that enables:

- **Navigation**: parent links for breadcrumb traversal
- **Discovery**: tags for filtering, related links for exploration
- **Search**: aliases for finding by short name, description for preview





## Methods

### FrontmatterBuilder.new(...)

⟨class_linker    : untyped⟩
⟨namespace_strip : untyped = nil⟩
⟨project_title   : untyped = "API Documentation"⟩
→ FrontmatterBuilder — a new instance of FrontmatterBuilder


```ruby
def initialize(class_linker, namespace_strip: nil, project_title: "API Documentation")
  @class_linker         = class_linker
  @namespace_strip      = namespace_strip
  @project_title        = project_title
  @inheritance_children = {} # Maps parent class path -> array of child class paths
end
```


---
### register_inheritance(...)
*Pre-compute inheritance relationships from full structure.

Must be called before build() to populate inherited-by fields.
Scans all classes to build parent->children mapping.*

⟨structure : Hash⟩ → Full documentation structure from Extractor


```ruby
def register_inheritance(structure)
  @inheritance_children = {}
  structure[:classes].each do |klass|
    parent = klass[:superclass]
    next unless parent && documentable_class?(parent)

    @inheritance_children[parent] ||= []
    @inheritance_children[parent] << klass[:path]
  end
end
```


---
### build(...)
*Build frontmatter hash for a class or module.*

⟨obj : Hash⟩ → Extracted object data from Extractor
→ Hash — Frontmatter fields in render order


---
### build_index
*Build frontmatter for index page.*

→ Hash — Minimal frontmatter for index


```ruby
def build_index
  {
    generated: Time.now.utc.iso8601,
    title:     @project_title,
    tags:      %w[index api-reference]
  }
end
```
