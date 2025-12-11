---
generated: 2025-12-11T22:51:37Z
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

`⟨output                 ⟩                      `
`⟨namespace_strip        ⟩                      `
`⟨include_specs          ⟩                      `
`⟨verbose                ⟩                      `
`⟨logger                 ⟩                      `
`⟨root                    = Dir.pwd⟩            `
`⟨github_repo             = nil⟩                `
`⟨github_branch           = "main"⟩             `
`⟨project_title           = "API Documentation"⟩`
`⟨inline_source_threshold = 10⟩                 `
⟶ `DriftChecker                                 ` — A new instance of DriftChecker


---
### check(...)
Check for drift between source and existing documentation.

`⟨structure : Hash⟩` — Documentation structure from Extractor


```ruby
# lib/chiridion/engine/drift_checker.rb : ~42
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

---

**Private:** `#check_file`:73, `#check_index`:57, `#check_objects`:63, `#content_changed?`:96, `#find_orphaned_files`:82, `#normalize`:98, `#output_path`:131, `#report_list`:124, `#report_results`:105, `#to_kebab_case`:138
