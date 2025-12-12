---
generated: 2025-12-12T17:59:26Z
title: type_merger.rb
source: lib/chiridion/engine/type_merger.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/type_merger.rb#L1
lines: 126
type: file
parent: engine
primary: Chiridion::Engine::TypeMerger
namespaces: [Chiridion::Engine::TypeMerger]
tags: [file, class]
description: Merges RBS type signatures with YARD documentation.
type-merger-methods:
  - merge_params(yard_params, rbs_data, class_path, method_name)
  - merge_return(yard_return, rbs_data, class_path, method_name)
  - TypeMerger.new(logger)
---

# Class: Chiridion::Engine::TypeMerger
**Extends:** Object

Merges RBS type signatures with YARD documentation.

RBS is treated as authoritative for types. When YARD and RBS disagree,
a warning is logged but RBS types are used. This ensures documentation
reflects the actual type contracts defined in sig/*.rbs.

## Constants
| Name | Value | Description |
|------|-------|-------------|
| `BOOLEAN_TYPES` | `%w[bool TrueClass FalseClass]` | Known type equivalences between YARD conventions and RBS. |
| `GENERIC_PREFIXES` | `{ "Hash" => "Hash[", "Array" => "Array[" }` |  |

## Attributes / Methods
`⟨merge_params(…) : Array<Hash>⟩` — Merge YARD params with RBS types - RBS is authoritative.
`⟨merge_return(…) : Hash       ⟩` — Merge YARD return with RBS return type - RBS is authoritative.

## Methods
### TypeMerger.new(...)
`⟨logger = nil⟩`
⟶ `TypeMerger ` — A new instance of TypeMerger

#### Source
```ruby
# lib/chiridion/engine/type_merger.rb:15
def initialize(logger = nil) = @logger = logger
```

---
### merge_params(...)
Merge YARD params with RBS types - RBS is authoritative.

`⟨yard_params : Array<Hash>⟩` — Parameters from YARD
`⟨rbs_data    : Hash       ⟩` — RBS signature data
`⟨class_path  : String     ⟩` — Class path for warnings
`⟨method_name : Symbol     ⟩` — Method name for warnings
⟶ `Array<Hash>             ` — Merged parameters

#### Source
```ruby
# lib/chiridion/engine/type_merger.rb:24
def merge_params(yard_params, rbs_data, class_path, method_name)
  return yard_params unless rbs_data&.dig(:params)

  rbs_params = rbs_data[:params]
  yard_params.map { |p| merge_single_param(p, rbs_params, class_path, method_name) }
end
```

---
### merge_return(...)
Merge YARD return with RBS return type - RBS is authoritative.

`⟨yard_return : Hash  ⟩` — Return info from YARD
`⟨rbs_data    : Hash  ⟩` — RBS signature data
`⟨class_path  : String⟩` — Class path for warnings
`⟨method_name : Symbol⟩` — Method name for warnings
⟶ `Hash               ` — Merged return info


---
**Private:** `#check_param_mismatch`:83, `#check_return_mismatch`:90, `#clean_param_name`:81, `#equivalent_types?`:109, `#exact_or_prefix_match?`:107, `#merge_description`:74, `#merge_single_param`:58, `#normalize_type`:116, `#types_compatible?`:98, `#warn_mismatch`:118
