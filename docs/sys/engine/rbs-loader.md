---
generated: 2025-12-10T22:33:19Z
title: Chiridion::Engine::RbsLoader
type: class
source: lib/chiridion/engine/rbs_loader.rb:9
description: Loads RBS type signatures from sig/ directory for documentation enrichment.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, rbs-loader]
aliases: [RbsLoader]
methods: [initialize, load]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/rbs_loader.rb#L9
---

# Chiridion::Engine::RbsLoader

Loads RBS type signatures from sig/ directory for documentation enrichment.

Parses RBS files and extracts method signatures to merge with YARD documentation,
providing accurate type information in generated docs.





## Methods

### RbsLoader.new(...)

⟨rbs_path : untyped⟩
⟨verbose  : untyped⟩
⟨logger   : untyped⟩
→ RbsLoader — a new instance of RbsLoader


```ruby
def initialize(rbs_path, verbose, logger)
  @rbs_path = rbs_path
  @verbose  = verbose
  @logger   = logger
end
```


---
### load
*Load all RBS files and return a hash of class -> method -> signature.*

→ Hash{String =] Hash{String =] Hash}} — Nested hash of signatures


```ruby
def load
  signatures = {}
  rbs_files  = Dir.glob("#{@rbs_path}/**/*.rbs")

  return signatures if rbs_files.empty?

  @logger.info "Loading #{rbs_files.size} RBS files..." if @verbose
  rbs_files.each { |file| parse_file(file, signatures) }
  signatures
end
```
