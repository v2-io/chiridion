---
generated: 2025-12-12T17:59:26Z
title: class_linker.rb
source: lib/chiridion/engine/class_linker.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/class_linker.rb#L1
lines: 204
type: file
parent: engine
primary: Chiridion::Engine::ClassLinker
namespaces: [Chiridion::Engine::ClassLinker]
tags: [file, class]
description: Converts class/module references to Obsidian wikilinks.
class-linker-methods:
  - ClassLinker.new(namespace_strip)
  - known?(class_name)
  - link(class_path, context)
  - linkify_docstring(text, context)
  - linkify_type(type_str, context)
  - register_classes(structure)
  - skip_type?(class_ref)
---

# Class: Chiridion::Engine::ClassLinker
**Extends:** Object

Converts class/module references to Obsidian wikilinks.

Handles various reference formats:
- Full paths: `Autopax::Foo::Bar` → `[[foo/bar|Bar]]`
- YARD curly braces: `[[engine/extractor|Extractor]]` → `[[extractor|Extractor]]`
- Relative names: `Writer` → `[[writer|Writer]]` (within same namespace)

## Constants
| Name | Value | Description |
|------|-------|-------------|
| `SKIP_TYPES` | `%w[Array Hash String Integer Float Symbol Boolean Object Tru` |  |

## Attributes / Methods
`⟨known_classes        : Hash<String, String>⟩` — Known classes mapped to doc paths
`⟨namespace_strip      : String              ⟩` — Namespace prefix to strip from paths
`⟨known?(…)            : Boolean             ⟩` — Check if a class is a known documentable class.
`⟨link(…)              : String              ⟩` — Convert a class path to a wikilink.
`⟨linkify_docstring(…) : String              ⟩` — Process a docstring, converting Class references to wikilinks.
`⟨linkify_type(…)      : String              ⟩` — Convert a type annotation to include wikilinks where possible.
`⟨register_classes(…)                        ⟩` — Register known classes from the documentation structure.
`⟨skip_type?(…)        : Boolean             ⟩`

## Methods
### ClassLinker.new(...)
`⟨namespace_strip = nil⟩`
⟶ `ClassLinker         ` — A new instance of ClassLinker

#### Source
```ruby
# lib/chiridion/engine/class_linker.rb:18
def initialize(namespace_strip: nil)
  @namespace_strip = namespace_strip
  @known_classes   = {}
end
```

---
### known?(...)
Check if a class is a known documentable class.

`⟨class_name : String⟩` — Class name to check
⟶ `Boolean           `

#### Source
```ruby
# lib/chiridion/engine/class_linker.rb:92
def known?(class_name) = @known_classes.key?(class_name)
```

---
### link(...)
Convert a class path to a wikilink.

`⟨class_path : String      ⟩` — Full or relative class path
`⟨context    : String = nil⟩` — Current class context for relative resolution
⟶ `String                  ` — Wikilink like `[[path|Name]]` or original if not found

#### Source
```ruby
# lib/chiridion/engine/class_linker.rb:41
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

`⟨text    : String      ⟩` — Docstring text
`⟨context : String = nil⟩` — Current class context
⟶ `String               ` — Text with {Class} converted to wikilinks

---
### linkify_type(...)
Convert a type annotation to include wikilinks where possible.

`⟨type_str : String      ⟩` — Type like `Array<Autopax::Foo>` or `Hash{String => Bar}`
`⟨context  : String = nil⟩` — Current class context
⟶ `String                ` — Formatted type with proper backtick placement

Returns formatted string with backticks around non-link parts.
Wikilinks must be outside backticks to render properly.

#### Source
```ruby
# lib/chiridion/engine/class_linker.rb:81
def linkify_type(type_str, context: nil)
  return "`Object`" if type_str.nil? || type_str.empty?

  segments = build_type_segments(type_str, context: context)
  format_type_segments(segments)
end
```

---
### register_classes(...)
Register known classes from the documentation structure.

`⟨structure : Hash⟩` — Documentation structure from Extractor

#### Source
```ruby
# lib/chiridion/engine/class_linker.rb:26
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
### skip_type?(...)
`⟨class_ref⟩`
⟶ `Boolean `

#### Source
```ruby
# lib/chiridion/engine/class_linker.rb:98
def skip_type?(class_ref) = SKIP_TYPES.include?(class_ref)
```


---
**Private:** `#build_type_segments`:103, `#doc_path`:189, `#format_mixed_segments`:145, `#format_pure_text`:140, `#format_type_segments`:132, `#pure_link?`:142, `#resolve`:164, `#segment_for_class`:122, `#to_kebab_case`:196
