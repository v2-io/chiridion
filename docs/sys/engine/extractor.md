---
generated: 2025-12-12T18:15:02Z
title: extractor.rb
source: lib/chiridion/engine/extractor.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/extractor.rb#L1
lines: 310
type: file
parent: engine
primary: Chiridion::Engine::Extractor
namespaces: [Chiridion::Engine::Extractor]
tags: [file, class]
description: Extracts documentation structure from YARD registry.
extractor-methods:
  - extract(registry, source_filter)
  - Extractor.new(rbs_types, spec_examples, namespace_filter, logger, rbs_file_namespaces, type_aliases)
---

# Class: Chiridion::Engine::Extractor
**Extends:** Object

Extracts documentation structure from YARD registry.

Parses Ruby source using YARD and builds a structured representation
of classes, modules, methods, and constants for documentation generation.
Merges RBS type signatures when available.

## Attributes / Methods
`⟨extract(…) : Hash⟩` — Extract documentation structure from YARD registry.

## Methods
### extract(...)
Extract documentation structure from YARD registry.

`⟨registry      : YARD::Registry     ⟩` — Parsed YARD registry
`⟨source_filter : Array<String> = nil⟩` — If provided, only objects from these
source files are marked for regeneration. All objects are still extracted
(for index generation), but only filtered ones get full documentation.
⟶ `Hash                              ` — Structure with :namespaces, :classes, :modules keys

---
### Extractor.new(...)
`⟨rbs_types                ⟩`
`⟨spec_examples            ⟩`
`⟨namespace_filter         ⟩`
`⟨logger              = nil⟩`
`⟨rbs_file_namespaces = {} ⟩`
`⟨type_aliases        = {} ⟩`
⟶ `Extractor               ` — A new instance of Extractor

#### Source
```ruby
# lib/chiridion/engine/extractor.rb:11
def initialize(rbs_types, spec_examples, namespace_filter, logger = nil, rbs_file_namespaces: {},
               type_aliases: {})
  @rbs_types           = rbs_types
  @spec_examples       = spec_examples
  @namespace_filter    = namespace_filter
  @logger              = logger
  @type_merger         = TypeMerger.new(logger)
  @rbs_file_namespaces = rbs_file_namespaces || {}
  @type_aliases        = type_aliases || {}
  @type_alias_lookup   = build_type_alias_lookup
end
```


---
**Private:** `#build_type_alias_lookup`:265, `#clean_docstring`:112, `#collect_referenced_types`:277, `#compute_end_line`:83, `#condense_attr_source`:223, `#extract_constants`:106, `#extract_method`:149, `#extract_methods`:124, `#extract_object`:53, `#extract_params`:175, `#extract_private_methods`:137, `#extract_return`:185, `#extract_see_tags`:81, `#extract_source`:201, `#extract_type_names`:300, `#find_rbs_file`:255, `#lookup_spec_data`:248, `#method_spec_behaviors`:246, `#method_spec_examples`:244, `#needs_regeneration?`:89, `#should_document?`:47, `#to_snake_case`:261
