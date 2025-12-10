---
generated: 2025-12-10T22:33:19Z
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

⟨rbs_types           : untyped⟩
⟨spec_examples       : untyped⟩
⟨namespace_filter    : untyped⟩
⟨logger              : untyped = nil⟩
⟨rbs_file_namespaces : untyped = {}⟩
⟨type_aliases        : untyped = {}⟩
→ Extractor — a new instance of Extractor


```ruby
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
*Extract documentation structure from YARD registry.*

⟨registry      : YARD::Registry⟩ → Parsed YARD registry
⟨source_filter : untyped = nil⟩
→ Hash — Structure with :namespaces, :classes, :modules keys
