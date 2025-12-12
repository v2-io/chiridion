---
generated: 2025-12-12T18:04:13Z
title: file_renderer.rb
source: lib/chiridion/engine/file_renderer.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/file_renderer.rb#L1
lines: 717
type: file
parent: engine
primary: Chiridion::Engine::FileRenderer
namespaces: [Chiridion::Engine::FileRenderer]
tags: [file, class]
description: Renders per-file documentation using Liquid templates.
file-renderer-methods:
  - FileRenderer.new(namespace_strip, include_specs, root, github_repo, github_branch, project_title, inline_source_threshold, templates_path)
  - register_classes(project)
  - render_file(file_doc, is_root)
  - render_index(project, index_description)
---

# Class: Chiridion::Engine::FileRenderer
**Extends:** Object

Renders per-file documentation using Liquid templates.

Takes FileDoc structures from SemanticExtractor and produces markdown
files grouped by source file rather than by class/module.

Design: One markdown file per source file. Each file contains documentation
for all namespaces (classes/modules) defined in that source file.

## Attributes / Methods
`⟨register_classes(…)         ⟩` — Register known classes for cross-reference linking.
`⟨render_file(…)      : String⟩` — Render documentation for a single source file.
`⟨render_index(…)     : String⟩` — Render the documentation index.

## Methods
### FileRenderer.new(...)
`⟨namespace_strip         = nil                ⟩`
`⟨include_specs           = false              ⟩`
`⟨root                    = Dir.pwd            ⟩`
`⟨github_repo             = nil                ⟩`
`⟨github_branch           = "main"             ⟩`
`⟨project_title           = "API Documentation"⟩`
`⟨inline_source_threshold = 10                 ⟩`
`⟨templates_path          = nil                ⟩`
⟶ `FileRenderer                                ` — A new instance of FileRenderer

---
### register_classes(...)
Register known classes for cross-reference linking.

`⟨project : ProjectDoc⟩` — Documentation structure

#### Source
```ruby
# lib/chiridion/engine/file_renderer.rb:36
def register_classes(project)
  structure = {
    classes: project.classes.map { |c| { path: c.path } },
    modules: project.modules.map { |m| { path: m.path } }
  }
  @class_linker.register_classes(structure)
end
```

---
### render_file(...)
Render documentation for a single source file.

`⟨file_doc : FileDoc        ⟩` — File documentation from SemanticExtractor
`⟨is_root  : Boolean = false⟩` — If true, append Obsidian embed for index
⟶ `String                   ` — Rendered markdown

---
### render_index(...)
Render the documentation index.

`⟨project           : ProjectDoc  ⟩` — Documentation structure
`⟨index_description : String = nil⟩` — Custom description
⟶ `String                         ` — Rendered markdown


---
**Private:** `#build_file_description`:166, `#build_file_frontmatter`:101, `#build_file_tags`:186, `#build_method_signatures`:129, `#build_namespace_data`:196, `#capitalize_first`:709, `#file_parent`:152, `#linkify_class`:220, `#make_relative`:680, `#method_display_name`:511, `#render_constants`:237, `#render_file_index`:646, `#render_frontmatter`:656, `#render_method`:384, `#render_methods_section`:370, `#render_mixins`:222, `#render_private_summary`:633, `#render_signature`:535, `#render_summary_section`:296, `#render_types_section`:276, `#simple_constant?`:268, `#source_to_link`:686, `#split_docstring`:607, `#to_kebab_case`:700
