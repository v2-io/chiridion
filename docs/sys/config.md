---
generated: 2025-12-11T22:51:37Z
title: Chiridion::Config
type: class
source: lib/chiridion/config.rb:23
description: Configuration for documentation generation.
inherits: Object
tags: [config]
aliases: [Config]
methods: [full_output_path, full_rbs_path, full_source_path, full_spec_path, github_branch, github_branch=, github_repo, github_repo=, include_specs, include_specs=, initialize, inline_source_threshold, inline_source_threshold=, load_file, load_hash, logger, logger=, namespace_filter, namespace_filter=, namespace_strip, namespace_strip=, output, output=, rbs_path, rbs_path=, root, root=, source_path, source_path=, spec_path, spec_path=, verbose, verbose=]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/config.rb#L23
---

# Chiridion::Config

Configuration for documentation generation.

Chiridion can be configured globally or per-engine instance.
All options have sensible defaults for common Ruby project layouts.

## Example

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





## Attributes

`⟨github_branch           : String⟩ ` — Git branch for source links
`⟨github_repo             : String⟩ ` — GitHub repository for source links (e.g., "user/repo")
`⟨include_specs           : Boolean⟩` — Whether to extract examples from spec files
`⟨inline_source_threshold : Integer⟩` — Maximum body lines for inline source display. Methods with body <= this many lines show their implementation inline. Set to nil or 0 to disable inline source. Default: 10.
`⟨logger                  : #info⟩  ` — Logger for output messages
`⟨namespace_filter        : String⟩ ` — Namespace prefix to filter (e.g., "MyProject::") Only classes/modules starting with this prefix are documented. If nil, all classes are included.
`⟨namespace_strip        ⟩          ` — (Write) Namespace prefix to strip from output paths Defaults to namespace_filter value.
`⟨output                  : String⟩ ` — Output directory for generated docs
`⟨rbs_path                : String⟩ ` — Path to RBS signatures directory (relative to root)
`⟨root                    : String⟩ ` — Root directory of the project (defaults to current directory)
`⟨source_path             : String⟩ ` — Source directory to document (relative to root)
`⟨spec_path               : String⟩ ` — Path to test directory (relative to root)
`⟨verbose                 : Boolean⟩` — Verbose output during generation

## Methods

### Config.new

⟶ `Config` — A new instance of Config


---
### namespace_strip
Namespace prefix to strip from output paths.
Defaults to namespace_filter if not explicitly set.

```ruby
# lib/chiridion/config.rb : ~86
def namespace_strip = @namespace_strip || @namespace_filter
```


---
### load_file(...)
Load configuration from a YAML file.

`⟨path : String⟩` — Path to YAML configuration file
⟶ `Config       ` — Self


```ruby
# lib/chiridion/config.rb : ~92
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
⟶ `Config     ` — Self


```ruby
# lib/chiridion/config.rb : ~104
def load_hash(data)
  data.each do |key, value|
    setter = :"#{key}="
    public_send(setter, value) if respond_to?(setter)
  end
  self
end
```


---
### full_source_path

⟶ `String` — Full path to source directory


```ruby
# lib/chiridion/config.rb : ~113
def full_source_path = File.join(root, source_path)
```


---
### full_output_path

⟶ `String` — Full path to output directory


```ruby
# lib/chiridion/config.rb : ~116
def full_output_path = File.join(root, output)
```


---
### full_spec_path

⟶ `String` — Full path to spec directory


```ruby
# lib/chiridion/config.rb : ~119
def full_spec_path = File.join(root, spec_path)
```


---
### full_rbs_path

⟶ `String` — Full path to RBS directory


```ruby
# lib/chiridion/config.rb : ~122
def full_rbs_path = File.join(root, rbs_path)
```
