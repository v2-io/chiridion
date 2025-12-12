---
generated: 2025-12-12T17:59:26Z
title: renderer.rb
source: lib/chiridion/engine/renderer.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/renderer.rb#L1
lines: 598
type: file
parent: engine
primary: Chiridion::Engine::Renderer
namespaces: [Chiridion::Engine::Renderer]
tags: [file, class]
description: Renders documentation to Obsidian-compatible markdown.
renderer-methods:
  - register_classes(structure)
  - render_class(klass)
  - render_index(structure)
  - render_module(mod)
  - render_type_aliases(type_aliases)
  - Renderer.new(namespace_strip, include_specs, root, github_repo, github_branch, project_title, index_description, templates_path, inline_source_threshold, rbs_attr_types)
---

# Class: Chiridion::Engine::Renderer
**Extends:** Object

Renders documentation to Obsidian-compatible markdown.

Uses Liquid templates for the document body content, while YAML frontmatter
is rendered directly in Ruby due to its complex formatting requirements
(flow vs block arrays, proper quoting, etc.).

### Template Customization
Templates are loaded from the gem's templates/ directory by default.
Override by passing a custom templates_path to the constructor.

### Enhanced Frontmatter
All generated documents include enhanced YAML frontmatter for Obsidian:
- **Navigation**: parent links for breadcrumb traversal
- **Discovery**: tags for filtering, related links for exploration
- **Search**: aliases for finding by short name, description for preview

## Attributes / Methods
`⟨register_classes(…)            ⟩` — Register known classes for cross-reference linking and inheritance.
`⟨render_class(…)        : String⟩` — Render class documentation.
`⟨render_index(…)        : String⟩` — Render the documentation index.
`⟨render_module(…)       : String⟩` — Render module documentation.
`⟨render_type_aliases(…) : String⟩` — Render type aliases reference page.

## Methods
### Renderer.new(...)
`⟨namespace_strip                              ⟩`
`⟨include_specs                                ⟩`
`⟨root                    = Dir.pwd            ⟩`
`⟨github_repo             = nil                ⟩`
`⟨github_branch           = "main"             ⟩`
`⟨project_title           = "API Documentation"⟩`
`⟨index_description       = nil                ⟩`
`⟨templates_path          = nil                ⟩`
`⟨inline_source_threshold = 10                 ⟩`
`⟨rbs_attr_types          = {}                 ⟩`
⟶ `Renderer                                    ` — A new instance of Renderer

---
### register_classes(...)
Register known classes for cross-reference linking and inheritance.

`⟨structure : Hash⟩` — Documentation structure from Extractor

#### Source
```ruby
# lib/chiridion/engine/renderer.rb:54
def register_classes(structure)
  @class_linker.register_classes(structure)
  @frontmatter_builder.register_inheritance(structure)
end
```

---
### render_class(...)
Render class documentation.

`⟨klass : Hash⟩` — Class data from Extractor
⟶ `String     ` — Markdown documentation

#### Source
```ruby
# lib/chiridion/engine/renderer.rb:88
def render_class(klass) = render_document(klass, include_mixins: true)
```

---
### render_index(...)
Render the documentation index.

`⟨structure : Hash⟩` — Documentation structure from Extractor
⟶ `String         ` — Markdown index

---
### render_module(...)
Render module documentation.

`⟨mod : Hash⟩` — Module data from Extractor
⟶ `String   ` — Markdown documentation

#### Source
```ruby
# lib/chiridion/engine/renderer.rb:94
def render_module(mod) = render_document(mod, include_mixins: false)
```

---
### render_type_aliases(...)
Render type aliases reference page.

`⟨type_aliases : Hash{String => Array<Hash>}⟩` — namespace -> types mapping
⟶ `String                                   ` — Markdown documentation


---
**Private:** `#attr_description`:414, `#attr_mode`:405, `#attr_type_str`:428, `#build_attr_inner`:383, `#build_document_frontmatter`:164, `#build_param_inner`:532, `#capitalize_first`:583, `#clean`:254, `#clean_param_name`:550, `#complex_constant?`:311, `#extract_param_prefix`:552, `#extract_return_type`:563, `#format_attr_line`:389, `#format_constant_value`:327, `#format_param_line`:543, `#format_source_with_lines`:256, `#inline_source_for`:482, `#link`:210, `#method_display_name`:498, `#normalize_type`:561, `#partition_attributes`:345, `#partition_constants`:309, `#relative_path`:204, `#render_attributes_section`:366, `#render_constants`:266, `#render_document`:137, `#render_frontmatter`:182, `#render_method`:459, `#render_methods_only`:336, `#render_mixins`:217, `#render_params_and_return`:513, `#render_private_methods_summary`:446, `#render_return_line`:574, `#render_see_also`:232, `#render_spec_examples`:242, `#render_types_section`:294, `#strip_freeze`:334, `#to_kebab_case`:590, `#useful_docstring?`:505
