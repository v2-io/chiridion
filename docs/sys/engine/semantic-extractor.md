---
generated: 2025-12-12T18:15:02Z
title: semantic_extractor.rb
source: lib/chiridion/engine/semantic_extractor.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/semantic_extractor.rb#L1
lines: 739
type: file
parent: engine
primary: Chiridion::Engine::SemanticExtractor
namespaces: [Chiridion::Engine::SemanticExtractor]
tags: [file, class]
description: Comprehensive semantic extraction from YARD registry.
semantic-extractor-methods:
  - extract(registry, title, description, root)
  - SemanticExtractor.new(rbs_types, rbs_attr_types, rbs_ivar_types, type_aliases, spec_examples, namespace_filter, logger)
---

# Class: Chiridion::Engine::SemanticExtractor
**Extends:** Object

**Includes:** [[engine/document-model|DocumentModel]]

Comprehensive semantic extraction from YARD registry.

Unlike the simpler Extractor, this captures ALL available metadata from
YARD and RBS, populating the DocumentModel structures completely. It
addresses the "data being discarded" issues documented in TODO.md.

Key improvements over Extractor:
- @option tags for hash parameter documentation
- @yield, @yieldparam, @yieldreturn for block documentation
- @api, @deprecated, @abstract, @note tags
- @raise exceptions
- Instance variable types (@rbs @name: Type)
- Method overloads from RBS

Design: Extract everything, render selectively.

## Attributes / Methods
`⟨extract(…) : ProjectDoc⟩` — Extract complete documentation from YARD registry.

## Methods
### extract(...)
Extract complete documentation from YARD registry.

`⟨registry    : YARD::Registry              ⟩` — Parsed YARD registry
`⟨title       : String = "API Documentation"⟩` — Project title
`⟨description : String = nil                ⟩` — Project description
`⟨root        : String = Dir.pwd            ⟩` — Project root for relative path calculation
⟶ `ProjectDoc                               ` — Complete documentation structure

---
### SemanticExtractor.new(...)
`⟨rbs_types             ⟩`
`⟨rbs_attr_types   = {} ⟩`
`⟨rbs_ivar_types   = {} ⟩`
`⟨type_aliases     = {} ⟩`
`⟨spec_examples    = {} ⟩`
`⟨namespace_filter = nil⟩`
`⟨logger           = nil⟩`
⟶ `SemanticExtractor    ` — A new instance of SemanticExtractor


---
**Private:** `#clean_docstring`:664, `#compute_end_line`:676, `#condense_attr_source`:699, `#extract_attributes`:210, `#extract_constants`:175, `#extract_deprecated`:168, `#extract_examples`:156, `#extract_ivars`:199, `#extract_local_type_aliases`:186, `#extract_method`:291, `#extract_methods`:275, `#extract_namespace`:121, `#extract_notes`:162, `#extract_options`:389, `#extract_overloads`:648, `#extract_raises`:632, `#extract_rbs_record_types`:423, `#extract_return`:500, `#extract_see_tags`:164, `#extract_source`:682, `#extract_yard_params`:342, `#extract_yields`:530, `#find_rbs_file`:715, `#group_by_file`:79, `#lookup_spec_data`:731, `#make_relative`:108, `#merge_descriptions`:656, `#merge_params`:359, `#method_spec_behaviors`:729, `#method_spec_examples`:727, `#parse_block_type`:583, `#parse_rbs_record_type`:442, `#resolve_attr_description`:266, `#resolve_attr_type`:254, `#should_document?`:114, `#split_record_pairs`:471, `#split_type_params`:602, `#to_snake_case`:721, `#to_type_alias_doc`:190
