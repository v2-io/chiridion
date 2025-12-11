---
generated: 2025-12-11T22:51:37Z
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

`⟨namespace_strip        ⟩                      `
`⟨include_specs          ⟩                      `
`⟨root                    = Dir.pwd⟩            `
`⟨github_repo             = nil⟩                `
`⟨github_branch           = "main"⟩             `
`⟨project_title           = "API Documentation"⟩`
`⟨index_description       = nil⟩                `
`⟨templates_path          = nil⟩                `
`⟨inline_source_threshold = 10⟩                 `
⟶ `Renderer                                     ` — A new instance of Renderer


---
### register_classes(...)
Register known classes for cross-reference linking and inheritance.

`⟨structure : Hash⟩` — Documentation structure from Extractor


```ruby
# lib/chiridion/engine/renderer.rb : ~52
def register_classes(structure)
  @class_linker.register_classes(structure)
  @frontmatter_builder.register_inheritance(structure)
end
```


---
### render_index(...)
Render the documentation index.

`⟨structure : Hash⟩` — Documentation structure from Extractor
⟶ `String          ` — Markdown index


---
### render_class(...)
Render class documentation.

`⟨klass : Hash⟩` — Class data from Extractor
⟶ `String      ` — Markdown documentation


```ruby
# lib/chiridion/engine/renderer.rb : ~86
def render_class(klass) = render_document(klass, include_mixins: true)
```


---
### render_module(...)
Render module documentation.

`⟨mod : Hash⟩` — Module data from Extractor
⟶ `String    ` — Markdown documentation


```ruby
# lib/chiridion/engine/renderer.rb : ~92
def render_module(mod) = render_document(mod, include_mixins: false)
```


---
### render_type_aliases(...)
Render type aliases reference page.

`⟨type_aliases : Hash{String =] Array[Hash]}⟩` — namespace -> types mapping
⟶ `String                                    ` — Markdown documentation

---

**Private:** `#attr_description`:396, `#attr_mode`:387, `#attr_type_str`:405, `#build_attr_inner`:365, `#build_document_frontmatter`:162, `#build_param_inner`:505, `#capitalize_first`:556, `#clean`:252, `#clean_param_name`:523, `#extract_param_prefix`:525, `#extract_return_type`:536, `#format_attr_line`:371, `#format_constant_value`:309, `#format_param_line`:516, `#format_source_with_lines`:254, `#inline_source_for`:455, `#link`:208, `#method_display_name`:471, `#normalize_type`:534, `#partition_attributes`:327, `#partition_constants`:307, `#relative_path`:202, `#render_attributes_section`:348, `#render_constants`:264, `#render_document`:135, `#render_frontmatter`:180, `#render_method`:431, `#render_methods_only`:318, `#render_mixins`:215, `#render_params_and_return`:486, `#render_private_methods_summary`:418, `#render_return_line`:547, `#render_see_also`:230, `#render_spec_examples`:240, `#render_types_section`:292, `#strip_freeze`:316, `#to_kebab_case`:563, `#useful_docstring?`:478
