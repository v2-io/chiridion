---
generated: 2025-12-11T22:51:37Z
title: Chiridion::Engine::ClassLinker
type: class
source: lib/chiridion/engine/class_linker.rb:11
description: Converts class/module references to Obsidian wikilinks.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, class-linker]
aliases: [ClassLinker]
constants: [SKIP_TYPES]
methods: [initialize, known?, known_classes, link, linkify_docstring, linkify_type, namespace_strip, register_classes, skip_type?]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/class_linker.rb#L11
---

# Chiridion::Engine::ClassLinker

Converts class/module references to Obsidian wikilinks.

Handles various reference formats:
- Full paths: `Autopax::Foo::Bar` → `[[foo/bar|Bar]]`
- YARD curly braces: `[[engine/extractor|Extractor]]` → `[[extractor|Extractor]]`
- Relative names: `Writer` → `[[writer|Writer]]` (within same namespace)

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `SKIP_TYPES` | `%w[Array Hash String Integer Float Symbol Boolean Object TrueClass FalseClass NilClass Proc<br />Class Module Numeric Enumerable Comparable void untyped nil self]` |  |



## Attributes

`⟨known_classes   : Hash<String, String>⟩` — (Read) Known classes mapped to doc paths
`⟨namespace_strip : String⟩              ` — (Read) Namespace prefix to strip from paths

## Methods

### ClassLinker.new(...)

`⟨namespace_strip = nil⟩`
⟶ `ClassLinker          ` — A new instance of ClassLinker


```ruby
# lib/chiridion/engine/class_linker.rb : ~18
def initialize(namespace_strip: nil)
  @namespace_strip = namespace_strip
  @known_classes   = {}
end
```


---
### register_classes(...)
Register known classes from the documentation structure.

`⟨structure : Hash⟩` — Documentation structure from Extractor


```ruby
# lib/chiridion/engine/class_linker.rb : ~26
def register_classes(structure)
  (structure[:classes] + structure[:modules]).each do |obj|
    path                         = obj[:path]
    @known_classes[path]         = doc_path(path)
    # Also register short name for relative lookups
    short_name                   = path.split("::").last
    @known_classes[short_name] ||= doc_path(path)
  end
end
```


---
### link(...)
Convert a class path to a wikilink.

`⟨class_path : String⟩` — Full or relative class path
`⟨context    = nil⟩   `
⟶ `String             ` — Wikilink like `[[path|Name]]` or original if not found


```ruby
# lib/chiridion/engine/class_linker.rb : ~41
def link(class_path, context: nil)
  display_name = class_path.split("::").last
  resolved     = resolve(class_path, context: context)
  return display_name unless resolved

  "[[#{resolved}|#{display_name}]]"
end
```


---
### linkify_docstring(...)
Process a docstring, converting Class references to wikilinks.

`⟨text    : String⟩` — Docstring text
`⟨context = nil⟩   `
⟶ `String          ` — Text with {Class} converted to wikilinks


```ruby
# lib/chiridion/engine/class_linker.rb : ~54
def linkify_docstring(text, context: nil)
  return text if text.nil? || text.empty?

  text.gsub(/\{([A-Z][\w:]*)\}/) do |_match|
    class_ref = Regexp.last_match(1)
    link(class_ref, context: context)
  end
end
```


---
### linkify_type(...)
Convert a type annotation to include wikilinks where possible.

Returns formatted string with backticks around non-link parts.
Wikilinks must be outside backticks to render properly.

`⟨type_str : String⟩` — Type like `Array<Autopax::Foo>` or `Hash{String => Bar}`
`⟨context  = nil⟩   `
⟶ `String           ` — Formatted type with proper backtick placement


```ruby
# lib/chiridion/engine/class_linker.rb : ~71
def linkify_type(type_str, context: nil)
  return "`Object`" if type_str.nil? || type_str.empty?

  segments = build_type_segments(type_str, context: context)
  format_type_segments(segments)
end
```


---
### known?(...)
Check if a class is a known documentable class.

`⟨class_name : String⟩` — Class name to check
⟶ `Boolean            `


```ruby
# lib/chiridion/engine/class_linker.rb : ~82
def known?(class_name) = @known_classes.key?(class_name)
```


---
### skip_type?(...)

`⟨class_ref⟩`
⟶ `Boolean  `


```ruby
# lib/chiridion/engine/class_linker.rb : ~88
def skip_type?(class_ref) = SKIP_TYPES.include?(class_ref)
```

---

**Private:** `#build_type_segments`:93, `#doc_path`:179, `#format_mixed_segments`:135, `#format_pure_text`:130, `#format_type_segments`:122, `#pure_link?`:132, `#resolve`:154, `#segment_for_class`:112, `#to_kebab_case`:186
