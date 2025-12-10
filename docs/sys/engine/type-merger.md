---
generated: 2025-12-10T22:33:19Z
title: Chiridion::Engine::TypeMerger
type: class
source: lib/chiridion/engine/type_merger.rb:10
description: Merges RBS type signatures with YARD documentation.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, type-merger]
aliases: [TypeMerger]
constants: [BOOLEAN_TYPES, GENERIC_PREFIXES]
methods: [initialize, merge_params, merge_return]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/type_merger.rb#L10
---

# Chiridion::Engine::TypeMerger

Merges RBS type signatures with YARD documentation.

RBS is treated as authoritative for types. When YARD and RBS disagree,
a warning is logged but RBS types are used. This ensures documentation
reflects the actual type contracts defined in sig/*.rbs.

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `BOOLEAN_TYPES` | `%w[bool TrueClass FalseClass]` | Known type equivalences between YARD conventions and RBS. |
| `GENERIC_PREFIXES` | `{ "Hash" => "Hash[", "Array" => "Array[" }` |  |



## Methods

### TypeMerger.new(...)

⟨logger : untyped = nil⟩
→ TypeMerger — a new instance of TypeMerger


```ruby
def initialize(logger = nil) = @logger = logger
```


---
### merge_params(...)
*Merge YARD params with RBS types - RBS is authoritative.*

⟨yard_params : Array[Hash]⟩ → Parameters from YARD
⟨rbs_data    : Hash⟩ → RBS signature data
⟨class_path  : String⟩ → Class path for warnings
⟨method_name : Symbol⟩ → Method name for warnings
→ Array[Hash] — Merged parameters


```ruby
def merge_params(yard_params, rbs_data, class_path, method_name)
  return yard_params unless rbs_data&.dig(:params)

  rbs_params = rbs_data[:params]
  yard_params.map { |p| merge_single_param(p, rbs_params, class_path, method_name) }
end
```


---
### merge_return(...)
*Merge YARD return with RBS return type - RBS is authoritative.*

⟨yard_return : Hash⟩ → Return info from YARD
⟨rbs_data    : Hash⟩ → RBS signature data
⟨class_path  : String⟩ → Class path for warnings
⟨method_name : Symbol⟩ → Method name for warnings
→ Hash — Merged return info


```ruby
def merge_return(yard_return, rbs_data, class_path, method_name)
  return yard_return unless rbs_data&.dig(:returns)

  rbs_return = rbs_data[:returns]

  if yard_return
    check_return_mismatch(yard_return, rbs_return, class_path, method_name)
    yard_return.merge(types: [rbs_return])
  else
    { types: [rbs_return], text: nil }
  end
end
```
