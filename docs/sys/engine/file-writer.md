---
generated: 2025-12-12T17:59:26Z
title: file_writer.rb
source: lib/chiridion/engine/file_writer.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/file_writer.rb#L1
lines: 160
type: file
parent: engine
primary: Chiridion::Engine::FileWriter
namespaces: [Chiridion::Engine::FileWriter]
tags: [file, class]
description: Writes per-file documentation to disk.
file-writer-methods:
  - FileWriter.new(output, logger, namespace_strip, include_specs, verbose, root, github_repo, github_branch, project_title, index_description, inline_source_threshold, templates_path)
  - write(project)
---

# Class: Chiridion::Engine::FileWriter
**Extends:** Object

Writes per-file documentation to disk.

Output structure mirrors source structure:
  lib/archema/query.rb -> docs/sys/query.md
  lib/archema/result.rb -> docs/sys/result.md

Handles smart write detection to avoid unnecessary file updates.

## Attributes / Methods
`⟨write(…)⟩` — Write all per-file documentation.

## Methods
### FileWriter.new(...)
`⟨output                                       ⟩`
`⟨logger                                       ⟩`
`⟨namespace_strip         = nil                ⟩`
`⟨include_specs           = false              ⟩`
`⟨verbose                 = false              ⟩`
`⟨root                    = Dir.pwd            ⟩`
`⟨github_repo             = nil                ⟩`
`⟨github_branch           = "main"             ⟩`
`⟨project_title           = "API Documentation"⟩`
`⟨index_description       = nil                ⟩`
`⟨inline_source_threshold = 10                 ⟩`
`⟨templates_path          = nil                ⟩`
⟶ `FileWriter                                  ` — A new instance of FileWriter

---
### write(...)
Write all per-file documentation.

`⟨project : ProjectDoc⟩` — Documentation structure from SemanticExtractor


---
**Private:** `#content_changed?`:123, `#find_root_file`:76, `#normalize`:125, `#output_path`:136, `#to_kebab_case`:152, `#to_snake_case`:86, `#write_file`:112, `#write_file_doc`:100, `#write_index`:93
