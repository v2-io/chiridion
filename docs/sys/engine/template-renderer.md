---
generated: 2025-12-12T17:59:26Z
title: template_renderer.rb
source: lib/chiridion/engine/template_renderer.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/template_renderer.rb#L1
lines: 275
type: file
parent: engine
primary: Chiridion::Engine::TemplateRenderer
namespaces:
  - Chiridion::Engine::TemplateRenderer
  - Chiridion::Engine::TemplateRenderer::Filters
tags: [file, class, module]
description: Renders documentation using Liquid templates.
template-renderer-methods:
  - render_constants(constants, complex_constants)
  - render_document(title, docstring, mixins, examples, spec_examples, see_also, constants_section, types_section, attributes_section, methods_section)
  - render_file(path, filename, line_count, namespaces, type_aliases)
  - render_index(title, description, classes, modules)
  - render_method(display_name, has_params, docstring, params, return_line, examples, behaviors, spec_examples, inline_source)
  - render_methods(methods)
  - render_type_aliases(title, description, namespaces)
  - render_types(types)
  - TemplateRenderer.new(templates_path)
filters-methods:
  - escape_pipes(input)
  - kebab_case(input)
  - normalize_headers(input, min_level)
  - strip_newlines(input)
  - strip_rbs_blocks(input)
---

# Class: Chiridion::Engine::TemplateRenderer
**Extends:** Object

Renders documentation using Liquid templates.

Templates are loaded from the gem's templates/ directory by default,
but can be overridden by specifying a custom templates_path.

Available templates:
- index.liquid: Documentation index page
- document.liquid: Class/module documentation
- method.liquid: Individual method documentation
- constants.liquid: Constants table and complex constant sections

## Attributes / Methods
`⟨render_constants(…)    : String⟩` — Render the constants section.
`⟨render_document(…)     : String⟩` — Render a class or module document.
`⟨render_file(…)         : String⟩` — Render a per-file documentation page.
`⟨render_index(…)        : String⟩` — Render the index template.
`⟨render_method(…)       : String⟩` — Render a single method.
`⟨render_methods(…)      : String⟩` — Render the methods section with separators.
`⟨render_type_aliases(…) : String⟩` — Render the type aliases reference page.
`⟨render_types(…)        : String⟩` — Render the types section (type aliases used by a class/module).

## Methods
### TemplateRenderer.new(...)
`⟨templates_path = nil⟩`
⟶ `TemplateRenderer   ` — A new instance of TemplateRenderer

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:85
def initialize(templates_path: nil)
  @templates_path = templates_path || default_templates_path
  @templates      = {}
  @environment    = Liquid::Environment.build do |env|
    env.register_filter(Filters)
  end
end
```

---
### render_constants(...)
Render the constants section.

`⟨constants         : Array<Hash>⟩` — Constants with :name, :value, :docstring, :is_complex
`⟨complex_constants : Array<Hash>⟩` — Complex constants for expanded rendering
⟶ `String                        ` — Rendered markdown

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:197
def render_constants(constants:, complex_constants:)
  render("constants", {
           "constants"         => stringify_keys(constants),
           "complex_constants" => stringify_keys(complex_constants)
         })
end
```

---
### render_document(...)
Render a class or module document.

`⟨title              : String          ⟩` — Class/module full path
`⟨docstring          : String          ⟩` — Main documentation (linkified)
`⟨mixins             : String = nil    ⟩` — Mixin line (e.g., "**Includes:** ...")
`⟨examples           : Array<Hash> = []⟩` — YARD examples with :name and :text
`⟨spec_examples      : String = nil    ⟩` — Rendered spec examples section
`⟨see_also           : String = nil    ⟩` — See also links
`⟨constants_section  : String = ""     ⟩` — Rendered constants section
`⟨types_section      : String = ""     ⟩` — Rendered types section (type aliases used by this class)
`⟨attributes_section : String = ""     ⟩` — Rendered attributes section
`⟨methods_section    : String = ""     ⟩` — Rendered methods section
⟶ `String                              ` — Rendered markdown

---
### render_file(...)
Render a per-file documentation page.

`⟨path         : String          ⟩` — Source file path (relative)
`⟨filename     : String          ⟩` — Just the filename
`⟨line_count   : Integer = nil   ⟩` — Total lines in source
`⟨namespaces   : Array<Hash> = []⟩` — Namespace data with pre-rendered sections
`⟨type_aliases : Array<Hash> = []⟩` — File-level type aliases
⟶ `String                        ` — Rendered markdown

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:234
def render_file(path:, filename:, line_count: nil, namespaces: [], type_aliases: [])
  render("file", {
           "path"         => path,
           "filename"     => filename,
           "line_count"   => line_count,
           "namespaces"   => stringify_keys(namespaces),
           "type_aliases" => stringify_keys(type_aliases)
         })
end
```

---
### render_index(...)
Render the index template.

`⟨title       : String     ⟩` — Project title
`⟨description : String     ⟩` — Index description
`⟨classes     : Array<Hash>⟩` — Class objects with :path and :link_path
`⟨modules     : Array<Hash>⟩` — Module objects with :path and :link_path
⟶ `String                  ` — Rendered markdown

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:100
def render_index(title:, description:, classes:, modules:)
  render("index", {
           "title"       => title,
           "description" => description,
           "classes"     => stringify_keys(classes),
           "modules"     => stringify_keys(modules)
         })
end
```

---
### render_method(...)
Render a single method.

`⟨display_name  : String            ⟩` — Method name (with class prefix if needed)
`⟨has_params    : Boolean = false   ⟩` — Whether method has parameters
`⟨docstring     : String = nil      ⟩` — Method description
`⟨params        : Array<String> = []⟩` — Formatted parameter lines
`⟨return_line   : String = nil      ⟩` — Formatted return line
`⟨examples      : Array<Hash> = []  ⟩` — YARD examples
`⟨behaviors     : Array<String> = []⟩` — Spec behavior descriptions
`⟨spec_examples : Array<Hash> = []  ⟩` — Spec code examples
`⟨inline_source : String = nil      ⟩` — Method source code to display inline
⟶ `String                           ` — Rendered markdown

---
### render_methods(...)
Render the methods section with separators.

`⟨methods : Array<String>⟩` — Pre-rendered method strings
⟶ `String                ` — Rendered markdown

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:188
def render_methods(methods:) = render("methods", {
  "methods" => methods
})
```

---
### render_type_aliases(...)
Render the type aliases reference page.

`⟨title       : String     ⟩` — Page title
`⟨description : String     ⟩` — Page description
`⟨namespaces  : Array<Hash>⟩` — Namespaces with :name and :types arrays
⟶ `String                  ` — Rendered markdown

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:218
def render_type_aliases(title:, description:, namespaces:)
  render("type_aliases", {
           "title"       => title,
           "description" => description,
           "namespaces"  => stringify_keys(namespaces)
         })
end
```

---
### render_types(...)
Render the types section (type aliases used by a class/module).

`⟨types : Array<Hash>⟩` — Types with :name, :definition, :description, :namespace
⟶ `String            ` — Rendered markdown

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:208
def render_types(types:) = render("types", {
  "types" => stringify_keys(types)
})
```


---
**Private:** `#default_templates_path`:246, `#load_template`:253, `#render`:248, `#stringify_keys`:263


---
# Module: Chiridion::Engine::TemplateRenderer::Filters
Custom Liquid filters for documentation rendering.

## Attributes / Methods
`⟨escape_pipes(…)     ⟩` — Escape pipe characters for markdown table cells.
`⟨kebab_case(…)       ⟩` — Convert to kebab case for file paths.
`⟨normalize_headers(…)⟩` — Normalize markdown headers to be subordinate to a given level.
`⟨strip_newlines(…)   ⟩` — Remove newlines for single-line table cells.
`⟨strip_rbs_blocks(…) ⟩` — Strip @rbs! blocks from docstrings (type metadata shouldn't be in docs).

## Methods
### escape_pipes(...)
Escape pipe characters for markdown table cells.

`⟨input⟩`

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:21
def escape_pipes(input)
  return "" if input.nil?

  input.to_s.gsub("|", "\\|")
end
```

---
### kebab_case(...)
Convert to kebab case for file paths.

`⟨input⟩`

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:35
def kebab_case(input)
  return "" if input.nil?

  input.to_s
       .gsub(/([A-Za-z])([vV]\d+)/, '\1-\2')
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
       .gsub(/([a-z\d])([A-Z])/, '\1-\2')
       .downcase
end
```

---
### normalize_headers(...)
`⟨input        ⟩`
`⟨min_level = 3⟩`

Normalize markdown headers to be subordinate to a given level.
Usage: {{ docstring | normalize_headers: 4 }}
Adjusts all headers so the minimum level becomes the specified level.

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:55
def normalize_headers(input, min_level = 3)
  return "" if input.nil? || input.to_s.empty?

  text  = input.to_s
  lines = text.lines

  # Find the minimum header level in the text
  header_levels = lines.filter_map do |line|
    match = line.match(/^(#+)\s/)
    match[1].length if match
  end

  return text if header_levels.empty?

  current_min = header_levels.min
  offset      = min_level.to_i - current_min
  return text if offset <= 0

  # Prepend offset number of # to all header lines
  prefix = "#" * offset
  lines.map do |line|
    if line.match?(/^#+\s/)
      prefix + line
    else
      line
    end
  end.join
end
```

---
### strip_newlines(...)
Remove newlines for single-line table cells.

`⟨input⟩`

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:28
def strip_newlines(input)
  return "" if input.nil?

  input.to_s.gsub(/\s*\n\s*/, " ").strip
end
```

---
### strip_rbs_blocks(...)
Strip @rbs! blocks from docstrings (type metadata shouldn't be in docs).

`⟨input⟩`

#### Source
```ruby
# lib/chiridion/engine/template_renderer.rb:46
def strip_rbs_blocks(input)
  return "" if input.nil?

  input.to_s.gsub(/@rbs![\s\S]*?(?=\n\n|\z)/, "").strip
end
```
