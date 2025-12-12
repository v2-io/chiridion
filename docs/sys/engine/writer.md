---
generated: 2025-12-12T17:59:26Z
title: writer.rb
source: lib/chiridion/engine/writer.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/writer.rb#L1
lines: 134
type: file
parent: engine
primary: Chiridion::Engine::Writer
namespaces: [Chiridion::Engine::Writer]
tags: [file, class]
description: Writes generated documentation files to disk.
writer-methods:
  - write(structure)
  - Writer.new(output, namespace_strip, include_specs, verbose, logger, root, github_repo, github_branch, project_title, index_description, inline_source_threshold, rbs_attr_types)
---

# Class: Chiridion::Engine::Writer
**Extends:** Object

Writes generated documentation files to disk.

Handles smart write detection to avoid unnecessary file updates when
only timestamps have changed but content is identical.

## Attributes / Methods
`⟨write(…)⟩` — Write all documentation files.

## Methods
### Writer.new(...)
`⟨output                                       ⟩`
`⟨namespace_strip                              ⟩`
`⟨include_specs                                ⟩`
`⟨verbose                                      ⟩`
`⟨logger                                       ⟩`
`⟨root                    = Dir.pwd            ⟩`
`⟨github_repo             = nil                ⟩`
`⟨github_branch           = "main"             ⟩`
`⟨project_title           = "API Documentation"⟩`
`⟨index_description       = nil                ⟩`
`⟨inline_source_threshold = 10                 ⟩`
`⟨rbs_attr_types          = {}                 ⟩`
⟶ `Writer                                      ` — A new instance of Writer

---
### write(...)
Write all documentation files.

`⟨structure : Hash⟩` — Documentation structure from Extractor

#### Source
```ruby
# lib/chiridion/engine/writer.rb:47
def write(structure)
  FileUtils.mkdir_p(@output)
  written, skipped = write_all_files(structure)
  @logger.info "  #{written} files written, #{skipped} unchanged"
end
```


---
**Private:** `#content_changed?`:110, `#normalize`:112, `#output_path`:119, `#to_kebab_case`:126, `#write_all_files`:55, `#write_file`:100, `#write_index`:75, `#write_object`:89, `#write_objects`:81, `#write_type_aliases`:65
