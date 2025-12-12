---
generated: 2025-12-12T17:59:26Z
title: post_processor.rb
source: lib/chiridion/engine/post_processor.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/post_processor.rb#L1
lines: 86
type: file
parent: engine
primary: Chiridion::Engine::PostProcessor
namespaces: [Chiridion::Engine::PostProcessor]
tags: [file, class]
description: Post-processes rendered markdown for consistent formatting.
post-processor-methods: [PostProcessor.process(content), process(content)]
---

# Class: Chiridion::Engine::PostProcessor
**Extends:** Object

Post-processes rendered markdown for consistent formatting.

Handles normalization that's easier to do as a final pass rather than
trying to get perfect output from templates. May grow into fuller
linting/validation over time.

Current normalizations:
- Collapse multiple consecutive newlines to single newlines
- Ensure 2 newlines before horizontal rules (---)
- Preserve frontmatter formatting

## Attributes / Methods
`⟨process(…) : String⟩`
`⟨process(…) : String⟩` — Normalize markdown content.

## Methods
### PostProcessor.process(...)
Normalize markdown content.

`⟨content : String⟩` — Raw markdown content
⟶ `String         ` — Normalized content

#### Source
```ruby
# lib/chiridion/engine/post_processor.rb:20
def self.process(content)
  new.process(content)
end
```

---
### process(...)
`⟨content : String⟩` — Raw markdown content
⟶ `String         ` — Normalized content

#### Source
```ruby
# lib/chiridion/engine/post_processor.rb:26
def process(content)
  # Split off frontmatter to preserve it exactly
  frontmatter, body = split_frontmatter(content)

  # Normalize the body
  normalized = normalize_newlines(body)

  # Reassemble
  frontmatter ? "#{frontmatter}\n\n#{normalized}" : normalized
end
```


---
**Private:** `#normalize_newlines`:69, `#split_frontmatter`:43
