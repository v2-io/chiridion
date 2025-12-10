---
generated: 2025-12-10T21:43:10Z
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

⟨output                  : untyped⟩
⟨namespace_strip         : untyped⟩
⟨include_specs           : untyped⟩
⟨verbose                 : untyped⟩
⟨logger                  : untyped⟩
⟨root                    : untyped = Dir.pwd⟩
⟨github_repo             : untyped = nil⟩
⟨github_branch           : untyped = "main"⟩
⟨project_title           : untyped = "API Documentation"⟩
⟨index_description       : untyped = nil⟩
⟨inline_source_threshold : untyped = 10⟩
→ Writer — a new instance of Writer


---
### write(...)
*Write all documentation files.*

⟨structure : Hash⟩ → Documentation structure from Extractor


```ruby
def write(structure)
  FileUtils.mkdir_p(@output)
  written, skipped = write_all_files(structure)
  @logger.info "  #{written} files written, #{skipped} unchanged"
end
```
