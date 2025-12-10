---
generated: 2025-12-10T22:33:19Z
title: Chiridion::Engine::DriftChecker
type: class
source: lib/chiridion/engine/drift_checker.rb:9
description: Detects when documentation is out of sync with source code.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, drift-checker]
aliases: [DriftChecker]
methods: [check, initialize]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/drift_checker.rb#L9
---

# Chiridion::Engine::DriftChecker

Detects when documentation is out of sync with source code.

Compares what would be generated against existing files.
Useful in CI pipelines to enforce documentation currency.





## Methods

### DriftChecker.new(...)

⟨output                  : untyped⟩
⟨namespace_strip         : untyped⟩
⟨include_specs           : untyped⟩
⟨verbose                 : untyped⟩
⟨logger                  : untyped⟩
⟨root                    : untyped = Dir.pwd⟩
⟨github_repo             : untyped = nil⟩
⟨github_branch           : untyped = "main"⟩
⟨project_title           : untyped = "API Documentation"⟩
⟨inline_source_threshold : untyped = 10⟩
→ DriftChecker — a new instance of DriftChecker


---
### check(...)
*Check for drift between source and existing documentation.*

⟨structure : Hash⟩ → Documentation structure from Extractor


```ruby
def check(structure)
  @renderer.register_classes(structure)

  drifted  = []
  missing  = []
  orphaned = find_orphaned_files(structure)

  check_index(structure, drifted, missing)
  check_objects(structure[:classes] + structure[:modules], drifted, missing)

  report_results(drifted, missing, orphaned)
end
```
