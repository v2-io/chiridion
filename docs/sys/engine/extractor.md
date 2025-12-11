---
generated: 2025-12-11T22:51:37Z
title: Chiridion::Engine::Extractor
type: class
source: lib/chiridion/engine/extractor.rb:10
description: Extracts documentation structure from YARD registry.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, extractor]
aliases: [Extractor]
methods: [extract, initialize]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/extractor.rb#L10
---

# Chiridion::Engine::Extractor

Extracts documentation structure from YARD registry.

Parses Ruby source using YARD and builds a structured representation
of classes, modules, methods, and constants for documentation generation.
Merges RBS type signatures when available.







## Methods

### Extractor.new(...)

`⟨rbs_types          ⟩      `
`⟨spec_examples      ⟩      `
`⟨namespace_filter   ⟩      `
`⟨logger              = nil⟩`
`⟨rbs_file_namespaces = {}⟩ `
`⟨type_aliases        = {}⟩ `
⟶ `Extractor                ` — A new instance of Extractor


```ruby
# lib/chiridion/engine/extractor.rb : ~11
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
### extract(...)
Extract documentation structure from YARD registry.

`⟨registry      : YARD::Registry⟩` — Parsed YARD registry
`⟨source_filter = nil⟩           `
⟶ `Hash                          ` — Structure with :namespaces, :classes, :modules keys

---

**Private:** `#build_type_alias_lookup`:262, `#clean_docstring`:112, `#collect_referenced_types`:274, `#compute_end_line`:83, `#condense_attr_source`:220, `#extract_constants`:106, `#extract_method`:146, `#extract_methods`:121, `#extract_object`:53, `#extract_params`:172, `#extract_private_methods`:134, `#extract_return`:182, `#extract_see_tags`:81, `#extract_source`:198, `#extract_type_names`:297, `#find_rbs_file`:252, `#lookup_spec_data`:245, `#method_spec_behaviors`:243, `#method_spec_examples`:241, `#needs_regeneration?`:89, `#should_document?`:47, `#to_snake_case`:258
