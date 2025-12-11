---
generated: 2025-12-11T22:51:37Z
title: Chiridion::Engine::Writer
type: class
source: lib/chiridion/engine/writer.rb:11
description: Writes generated documentation files to disk.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, writer]
aliases: [Writer]
methods: [initialize, write]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/writer.rb#L11
---

# Chiridion::Engine::Writer

Writes generated documentation files to disk.

Handles smart write detection to avoid unnecessary file updates when
only timestamps have changed but content is identical.







## Methods

### Writer.new(...)

`⟨output                 ⟩                      `
`⟨namespace_strip        ⟩                      `
`⟨include_specs          ⟩                      `
`⟨verbose                ⟩                      `
`⟨logger                 ⟩                      `
`⟨root                    = Dir.pwd⟩            `
`⟨github_repo             = nil⟩                `
`⟨github_branch           = "main"⟩             `
`⟨project_title           = "API Documentation"⟩`
`⟨index_description       = nil⟩                `
`⟨inline_source_threshold = 10⟩                 `
⟶ `Writer                                       ` — A new instance of Writer


---
### write(...)
Write all documentation files.

`⟨structure : Hash⟩` — Documentation structure from Extractor


```ruby
# lib/chiridion/engine/writer.rb : ~45
def write(structure)
  FileUtils.mkdir_p(@output)
  written, skipped = write_all_files(structure)
  @logger.info "  #{written} files written, #{skipped} unchanged"
end
```

---

**Private:** `#content_changed?`:108, `#normalize`:110, `#output_path`:117, `#to_kebab_case`:124, `#write_all_files`:53, `#write_file`:98, `#write_index`:73, `#write_object`:87, `#write_objects`:79, `#write_type_aliases`:63
