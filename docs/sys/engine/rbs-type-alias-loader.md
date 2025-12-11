---
generated: 2025-12-11T22:51:37Z
title: Chiridion::Engine::RbsTypeAliasLoader
type: class
source: lib/chiridion/engine/rbs_type_alias_loader.rb:22
description: Extracts RBS type alias definitions from generated .rbs files.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, rbs-type-alias-loader]
aliases: [RbsTypeAliasLoader]
methods: [initialize, load]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/rbs_type_alias_loader.rb#L22
---

# Chiridion::Engine::RbsTypeAliasLoader

Extracts RBS type alias definitions from generated .rbs files.

Reads type aliases from RBS files (typically in sig/generated/) which have
already been properly parsed by RBS::Inline. This is more reliable than
re-parsing @rbs! blocks ourselves.

RBS format is straightforward:
  module Namespace
    # Description comment
    type name = definition
  end

## Example

****

```ruby
loader = RbsTypeAliasLoader.new(true, logger, rbs_dir: "sig/generated")
type_aliases = loader.load
# => { "Archema" => [{ name: "attribute_value", definition: "...", ... }] }
```







## Methods

### RbsTypeAliasLoader.new(...)

`⟨verbose⟩           `
`⟨logger ⟩           `
`⟨rbs_dir = nil⟩     `
⟶ `RbsTypeAliasLoader` — A new instance of RbsTypeAliasLoader


```ruby
# lib/chiridion/engine/rbs_type_alias_loader.rb : ~23
def initialize(verbose, logger, rbs_dir: nil)
  @verbose = verbose
  @logger  = logger
  @rbs_dir = rbs_dir
end
```


---
### load
Extract type aliases from generated RBS files.

⟶ `Hash{String =] Array[Hash]}` — Namespace -> array of type definitions

---

**Private:** `#parse_rbs_file`:55
