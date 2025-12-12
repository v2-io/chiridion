---
generated: 2025-12-12T17:59:26Z
title: rbs_loader.rb
source: lib/chiridion/engine/rbs_loader.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/rbs_loader.rb#L1
lines: 150
type: file
parent: engine
primary: Chiridion::Engine::RbsLoader
namespaces: [Chiridion::Engine::RbsLoader]
tags: [file, class]
description: Loads RBS type signatures from sig/ directory for documentation enrichment.
rbs-loader-methods: [load, RbsLoader.new(rbs_path, verbose, logger)]
---

# Class: Chiridion::Engine::RbsLoader
**Extends:** Object

Loads RBS type signatures from sig/ directory for documentation enrichment.

Parses RBS files and extracts method signatures to merge with YARD documentation,
providing accurate type information in generated docs.

## Attributes / Methods
`⟨load : Hash{String => Hash{String => Hash}}⟩` — Load all RBS files and return a hash of class -> method -> signature.

## Methods
### RbsLoader.new(...)
`⟨rbs_path  ⟩`
`⟨verbose   ⟩`
`⟨logger    ⟩`
⟶ `RbsLoader` — A new instance of RbsLoader

#### Source
```ruby
# lib/chiridion/engine/rbs_loader.rb:10
def initialize(rbs_path, verbose, logger)
  @rbs_path = rbs_path
  @verbose  = verbose
  @logger   = logger
end
```

---
### load
Load all RBS files and return a hash of class -> method -> signature.

⟶ `Hash{String => Hash{String => Hash}}` — Nested hash of signatures

#### Source
```ruby
# lib/chiridion/engine/rbs_loader.rb:19
def load
  signatures = {}
  rbs_files  = Dir.glob("#{@rbs_path}/**/*.rbs")

  return signatures if rbs_files.empty?

  @logger.info "Loading #{rbs_files.size} RBS files..." if @verbose
  rbs_files.each { |file| parse_file(file, signatures) }
  signatures
end
```


---
**Private:** `#extract_attr_signature`:61, `#extract_class_name`:45, `#extract_method_signature`:53, `#parse_file`:32, `#parse_params`:92, `#parse_signature`:77, `#parse_single_param`:105, `#split_respecting_brackets`:120
