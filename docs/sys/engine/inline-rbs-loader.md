---
generated: 2025-12-12T17:59:26Z
title: inline_rbs_loader.rb
source: lib/chiridion/engine/inline_rbs_loader.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/inline_rbs_loader.rb#L1
lines: 207
type: file
parent: engine
primary: Chiridion::Engine::InlineRbsLoader
namespaces: [Chiridion::Engine::InlineRbsLoader]
tags: [file, class]
description: Extracts RBS type signatures from inline annotations in Ruby source.
inline-rbs-loader-methods:
  - InlineRbsLoader.new(verbose, logger)
  - load(source_files)
---

# Class: Chiridion::Engine::InlineRbsLoader
**Extends:** Object

Extracts RBS type signatures from inline annotations in Ruby source.

Supports the rbs-inline format where types are specified in comments:

  # @rbs param: String -- description
  # @rbs return: Integer
  def method(param)

This is the preferred way to specify types in source code, as it keeps
type information co-located with the code. The RbsLoader handles
separate sig/ files as a fallback.

**See also:** https://github.com/soutaro/rbs-inline

## Attributes / Methods
`⟨load(…) : Array(Hash, Hash, Hash)⟩` — Extract inline RBS annotations from Ruby source files.

## Methods
### InlineRbsLoader.new(...)
`⟨verbose         ⟩`
`⟨logger          ⟩`
⟶ `InlineRbsLoader` — A new instance of InlineRbsLoader

#### Source
```ruby
# lib/chiridion/engine/inline_rbs_loader.rb:19
def initialize(verbose, logger)
  @verbose = verbose
  @logger  = logger
end
```

---
### load(...)
Extract inline RBS annotations from Ruby source files.

`⟨source_files : Array<String>⟩` — Paths to Ruby files
⟶ `Array(Hash, Hash, Hash)    ` — [signatures, rbs_file_namespaces, attr_types]
- signatures: class -> method -> signature
- rbs_file_namespaces: file -> [namespaces] for files with @rbs content
- attr_types: class -> attr_name -> { type:, desc: } (from #: annotations or @rbs! blocks)


---
**Private:** `#build_signature`:185, `#capitalize_first`:178, `#current_namespace`:176, `#parse_file`:48
