---
generated: 2025-12-12T17:59:26Z
title: generated_rbs_loader.rb
source: lib/chiridion/engine/generated_rbs_loader.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/generated_rbs_loader.rb#L1
lines: 344
type: file
parent: engine
primary: Chiridion::Engine::GeneratedRbsLoader
namespaces:
  - Chiridion::Engine::GeneratedRbsLoader
  - Chiridion::Engine::GeneratedRbsLoader::Result
tags: [file, class]
description: Comprehensive loader for RBS::Inline-generated .rbs files.
generated-rbs-loader-methods:
  - GeneratedRbsLoader.new(verbose, logger)
  - load(rbs_dir)
---

# Class: Chiridion::Engine::GeneratedRbsLoader
**Extends:** Object

Comprehensive loader for RBS::Inline-generated .rbs files.

Unlike the simpler RbsLoader, this extracts ALL available information
from generated RBS files:

- Method signatures with parameter types and return types
- Instance variable declarations (@name: Type)
- Attribute declarations (attr_reader name: Type)
- Type aliases (type name = definition)
- Class/module structure with comments

The generated RBS files are authoritative - they've been properly parsed
by rbs-inline from the source annotations. We just need to read them.

### Example
****

```ruby
loader = GeneratedRbsLoader.new(verbose: true, logger: logger)
data = loader.load("sig/generated")
# => { signatures: {...}, ivars: {...}, attrs: {...}, type_aliases: {...} }
```

## Attributes / Methods
`⟨load(…) : Result⟩` — Load all data from generated RBS directory.

## Methods
### GeneratedRbsLoader.new(...)
`⟨verbose = false    ⟩`
`⟨logger  = nil      ⟩`
⟶ `GeneratedRbsLoader` — A new instance of GeneratedRbsLoader

#### Source
```ruby
# lib/chiridion/engine/generated_rbs_loader.rb:34
def initialize(verbose: false, logger: nil)
  @verbose = verbose
  @logger  = logger
end
```

---
### load(...)
Load all data from generated RBS directory.

`⟨rbs_dir : String⟩` — Path to generated RBS directory (e.g., "sig/generated")
⟶ `Result         ` — All extracted data


---
**Private:** `#capitalize_first`:306, `#empty_result`:70, `#extract_first_line_desc`:212, `#log_stats`:80, `#parse_file`:90, `#parse_params`:275, `#parse_signature`:230, `#parse_single_param`:288, `#split_respecting_brackets`:314


---
# Class: Chiridion::Engine::GeneratedRbsLoader::Result
**Extends:** Data

Result structure from loading.

## Attributes / Methods
`⟨attrs        : Object⟩` — The current value of attrs
`⟨ivars        : Object⟩` — The current value of ivars
`⟨overloads    : Object⟩` — The current value of overloads
`⟨signatures   : Object⟩` — The current value of signatures
`⟨type_aliases : Object⟩` — The current value of type_aliases
