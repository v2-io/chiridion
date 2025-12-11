---
generated: 2025-12-11T22:51:37Z
title: Chiridion::Engine::TemplateRenderer
type: class
source: lib/chiridion/engine/template_renderer.rb:17
description: Renders documentation using Liquid templates.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, template-renderer]
aliases: [TemplateRenderer]
methods: [initialize, render_constants, render_document, render_index, render_method, render_methods, render_type_aliases, render_types]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/template_renderer.rb#L17
---

# Chiridion::Engine::TemplateRenderer

Renders documentation using Liquid templates.

Templates are loaded from the gem's templates/ directory by default,
but can be overridden by specifying a custom templates_path.

Available templates:
- index.liquid: Documentation index page
- document.liquid: Class/module documentation
- method.liquid: Individual method documentation
- constants.liquid: Constants table and complex constant sections







## Methods

### TemplateRenderer.new(...)

`⟨templates_path = nil⟩`
⟶ `TemplateRenderer    ` — A new instance of TemplateRenderer


```ruby
# lib/chiridion/engine/template_renderer.rb : ~46
def initialize(templates_path: nil)
  @templates_path = templates_path || default_templates_path
  @templates      = {}
  @environment    = Liquid::Environment.build do |env|
    env.register_filter(Filters)
  end
end
```


---
### render_index(...)
Render the index template.

`⟨title      ⟩`
`⟨description⟩`
`⟨classes    ⟩`
`⟨modules    ⟩`
⟶ `String     ` — Rendered markdown


```ruby
# lib/chiridion/engine/template_renderer.rb : ~61
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
### render_document(...)
Render a class or module document.

`⟨title             ⟩      `
`⟨docstring         ⟩      `
`⟨mixins             = nil⟩`
`⟨examples           = []⟩ `
`⟨spec_examples      = nil⟩`
`⟨see_also           = nil⟩`
`⟨constants_section  = ""⟩ `
`⟨types_section      = ""⟩ `
`⟨attributes_section = ""⟩ `
`⟨methods_section    = ""⟩ `
⟶ `String                  ` — Rendered markdown


---
### render_method(...)
Render a single method.

`⟨display_name ⟩        `
`⟨has_params    = false⟩`
`⟨docstring     = nil⟩  `
`⟨params        = []⟩   `
`⟨return_line   = nil⟩  `
`⟨examples      = []⟩   `
`⟨behaviors     = []⟩   `
`⟨spec_examples = []⟩   `
`⟨inline_source = nil⟩  `
⟶ `String               ` — Rendered markdown


---
### render_methods(...)
Render the methods section with separators.

`⟨methods⟩`
⟶ `String ` — Rendered markdown


```ruby
# lib/chiridion/engine/template_renderer.rb : ~149
def render_methods(methods:) = render("methods", {
  "methods" => methods
})
```


---
### render_constants(...)
Render the constants section.

`⟨constants        ⟩`
`⟨complex_constants⟩`
⟶ `String           ` — Rendered markdown


```ruby
# lib/chiridion/engine/template_renderer.rb : ~158
def render_constants(constants:, complex_constants:)
  render("constants", {
           "constants"         => stringify_keys(constants),
           "complex_constants" => stringify_keys(complex_constants)
         })
end
```


---
### render_types(...)
Render the types section (type aliases used by a class/module).

`⟨types⟩ `
⟶ `String` — Rendered markdown


```ruby
# lib/chiridion/engine/template_renderer.rb : ~169
def render_types(types:) = render("types", {
  "types" => stringify_keys(types)
})
```


---
### render_type_aliases(...)
Render the type aliases reference page.

`⟨title      ⟩`
`⟨description⟩`
`⟨namespaces ⟩`
⟶ `String     ` — Rendered markdown


```ruby
# lib/chiridion/engine/template_renderer.rb : ~179
def render_type_aliases(title:, description:, namespaces:)
  render("type_aliases", {
           "title"       => title,
           "description" => description,
           "namespaces"  => stringify_keys(namespaces)
         })
end
```

---

**Private:** `#default_templates_path`:189, `#load_template`:196, `#render`:191, `#stringify_keys`:206
