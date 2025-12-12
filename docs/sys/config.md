---
generated: 2025-12-12T17:59:26Z
title: config.rb
source: lib/chiridion/config.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/config.rb#L1
lines: 128
type: file
parent: chiridion
primary: Chiridion::Config
namespaces: [Chiridion::Config]
tags: [file, class]
description: Configuration for documentation generation.
config-methods:
  - Config.new
  - full_output_path
  - full_rbs_path
  - full_source_path
  - full_spec_path
  - load_file(path)
  - load_hash(data)
  - namespace_strip
---

# Class: Chiridion::Config
**Extends:** Object

Configuration for documentation generation.

Chiridion can be configured globally or per-engine instance.
All options have sensible defaults for common Ruby project layouts.

### Example
**Global configuration**

```ruby
Chiridion.configure do |config|
  config.output = 'docs/sys'
  config.namespace_filter = 'MyProject::'
  config.github_repo = 'user/repo'
end
```

**Per-project configuration file**

```ruby
# .chiridion.yml
output: docs/sys
namespace_filter: MyProject::
github_repo: user/repo
include_specs: true
```

## Attributes / Methods
`⟨github_branch           : String ⟩` — Git branch for source links
`⟨github_repo             : String ⟩` — GitHub repository for source links (e.g., "user/repo")
`⟨include_specs           : Boolean⟩` — Whether to extract examples from spec files
`⟨inline_source_threshold : Integer⟩` — Maximum body lines for inline source display.
`⟨logger                  : #info  ⟩` — Logger for output messages
`⟨namespace_filter        : String ⟩` — Namespace prefix to filter (e.g., "MyProject::")
`⟨namespace_strip                  ⟩` — (Write)
`⟨output                  : String ⟩` — Output directory for generated docs
`⟨output_mode             : Symbol ⟩` — Output organization strategy (:per_class or :per_file)
`⟨rbs_path                : String ⟩` — Path to RBS signatures directory (relative to root)
`⟨root                    : String ⟩` — Root directory of the project (defaults to current directory)
`⟨source_path             : String ⟩` — Source directory to document (relative to root)
`⟨spec_path               : String ⟩` — Path to test directory (relative to root)
`⟨verbose                 : Boolean⟩` — Verbose output during generation
`⟨full_output_path        : String ⟩`
`⟨full_rbs_path           : String ⟩`
`⟨full_source_path        : String ⟩`
`⟨full_spec_path          : String ⟩`
`⟨load_file(…)            : Config ⟩` — Load configuration from a YAML file.
`⟨load_hash(…)            : Config ⟩` — Load configuration from a hash.
`⟨namespace_strip                  ⟩` — Namespace prefix to strip from output paths.

## Methods
### full_output_path
⟶ `String` — Full path to output directory

#### Source
```ruby
# lib/chiridion/config.rb:120
def full_output_path = File.join(root, output)
```

---
### full_rbs_path
⟶ `String` — Full path to RBS directory

#### Source
```ruby
# lib/chiridion/config.rb:126
def full_rbs_path = File.join(root, rbs_path)
```

---
### full_source_path
⟶ `String` — Full path to source directory

#### Source
```ruby
# lib/chiridion/config.rb:117
def full_source_path = File.join(root, source_path)
```

---
### full_spec_path
⟶ `String` — Full path to spec directory

#### Source
```ruby
# lib/chiridion/config.rb:123
def full_spec_path = File.join(root, spec_path)
```

---
### Config.new
⟶ `Config` — A new instance of Config

---
### load_file(...)
Load configuration from a YAML file.

`⟨path : String⟩` — Path to YAML configuration file
⟶ `Config      ` — Self

#### Source
```ruby
# lib/chiridion/config.rb:96
def load_file(path)
  return self unless File.exist?(path)

  require "yaml"
  data = YAML.safe_load_file(path, symbolize_names: true)
  load_hash(data)
end
```

---
### load_hash(...)
Load configuration from a hash.

`⟨data : Hash⟩` — Configuration values
⟶ `Config    ` — Self

#### Source
```ruby
# lib/chiridion/config.rb:108
def load_hash(data)
  data.each do |key, value|
    setter = :"#{key}="
    public_send(setter, value) if respond_to?(setter)
  end
  self
end
```

---
### namespace_strip
Namespace prefix to strip from output paths.
Defaults to namespace_filter if not explicitly set.

#### Source
```ruby
# lib/chiridion/config.rb:90
def namespace_strip = @namespace_strip || @namespace_filter
```
