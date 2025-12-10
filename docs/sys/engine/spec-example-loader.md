---
generated: 2025-12-10T22:33:19Z
title: Chiridion::Engine::SpecExampleLoader
type: class
source: lib/chiridion/engine/spec_example_loader.rb:9
description: Extracts usage examples from RSpec files.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, spec-example-loader]
aliases: [SpecExampleLoader]
methods: [initialize, load]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/spec_example_loader.rb#L9
---

# Chiridion::Engine::SpecExampleLoader

Extracts usage examples from RSpec files.

Parses spec files to find `let` declarations, `subject` blocks, and
test descriptions that can serve as documentation examples.





## Methods

### SpecExampleLoader.new(...)

⟨spec_path : untyped⟩
⟨verbose   : untyped⟩
⟨logger    : untyped⟩
→ SpecExampleLoader — a new instance of SpecExampleLoader


```ruby
def initialize(spec_path, verbose, logger)
  @spec_path = spec_path
  @verbose   = verbose
  @logger    = logger
end
```


---
### load
*Load spec examples for all spec files.*

→ Hash{String =] Hash} — Class path => { method_examples:, behaviors:, lets:, subjects: }


```ruby
def load
  examples   = {}
  spec_files = Dir.glob("#{@spec_path}/**/*_spec.rb")

  return examples if spec_files.empty?

  @logger.info "Loading examples from #{spec_files.size} spec files..." if @verbose
  spec_files.each { |file| parse_file(file, examples) }
  examples
end
```
