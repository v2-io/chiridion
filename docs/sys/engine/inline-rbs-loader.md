---
generated: 2025-12-11T22:51:37Z
title: Chiridion::Engine::InlineRbsLoader
type: class
source: lib/chiridion/engine/inline_rbs_loader.rb:18
description: Extracts RBS type signatures from inline annotations in Ruby source.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, inline-rbs-loader]
aliases: [InlineRbsLoader]
methods: [initialize, load]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/inline_rbs_loader.rb#L18
---

# Chiridion::Engine::InlineRbsLoader

Extracts RBS type signatures from inline annotations in Ruby source.

Supports the rbs-inline format where types are specified in comments:

  # @rbs param: String -- description
  # @rbs return: Integer
  def method(param)

This is the preferred way to specify types in source code, as it keeps
type information co-located with the code. The RbsLoader handles
separate sig/ files as a fallback.

**See also:** https://github.com/soutaro/rbs-inline







## Methods

### InlineRbsLoader.new(...)

`⟨verbose⟩        `
`⟨logger ⟩        `
⟶ `InlineRbsLoader` — A new instance of InlineRbsLoader


```ruby
# lib/chiridion/engine/inline_rbs_loader.rb : ~19
def initialize(verbose, logger)
  @verbose = verbose
  @logger  = logger
end
```


---
### load(...)
Extract inline RBS annotations from Ruby source files.

`⟨source_files : Array[String]⟩` — Paths to Ruby files
⟶ `Array(Hash, Hash)           ` — [signatures, rbs_file_namespaces]
- signatures: class -> method -> signature
- rbs_file_namespaces: file -> [namespaces] for files with @rbs content

---

**Private:** `#build_signature`:130, `#capitalize_first`:123, `#current_namespace`:121, `#parse_file`:46
