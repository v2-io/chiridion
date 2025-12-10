---
generated: 2025-12-10T22:33:19Z
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





## Methods

### root

→ String — Root directory of the project (defaults to current directory)


```ruby
def root
  @root
end
```


---
### root=(...)

⟨value : untyped⟩
→ String — Root directory of the project (defaults to current directory)


```ruby
def root=(value)
  @root = value
end
```


---
### source_path

→ String — Source directory to document (relative to root)


```ruby
def source_path
  @source_path
end
```


---
### source_path=(...)

⟨value : untyped⟩
→ String — Source directory to document (relative to root)


```ruby
def source_path=(value)
  @source_path = value
end
```


---
### output

→ String — Output directory for generated docs


```ruby
def output
  @output
end
```


---
### output=(...)

⟨value : untyped⟩
→ String — Output directory for generated docs


```ruby
def output=(value)
  @output = value
end
```


---
### namespace_filter

→ String — Namespace prefix to filter (e.g., "MyProject::")
Only classes/modules starting with this prefix are documented.
If nil, all classes are included.


```ruby
def namespace_filter
  @namespace_filter
end
```


---
### namespace_filter=(...)

⟨value : untyped⟩
→ String — Namespace prefix to filter (e.g., "MyProject::")
Only classes/modules starting with this prefix are documented.
If nil, all classes are included.


```ruby
def namespace_filter=(value)
  @namespace_filter = value
end
```


---
### namespace_strip
*Namespace prefix to strip from output paths.
Defaults to namespace_filter if not explicitly set.*

```ruby
def namespace_strip
  @namespace_strip
end
```


---
### namespace_strip=(...)

⟨value : untyped⟩
→ String — Namespace prefix to strip from output paths
Defaults to namespace_filter value.


```ruby
def namespace_strip=(value)
  @namespace_strip = value
end
```


---
### github_repo

→ String — GitHub repository for source links (e.g., "user/repo")


```ruby
def github_repo
  @github_repo
end
```


---
### github_repo=(...)

⟨value : untyped⟩
→ String — GitHub repository for source links (e.g., "user/repo")


```ruby
def github_repo=(value)
  @github_repo = value
end
```


---
### github_branch

→ String — Git branch for source links


```ruby
def github_branch
  @github_branch
end
```


---
### github_branch=(...)

⟨value : untyped⟩
→ String — Git branch for source links


```ruby
def github_branch=(value)
  @github_branch = value
end
```


---
### include_specs

→ Boolean — Whether to extract examples from spec files


```ruby
def include_specs
  @include_specs
end
```


---
### include_specs=(...)

⟨value : untyped⟩
→ Boolean — Whether to extract examples from spec files


```ruby
def include_specs=(value)
  @include_specs = value
end
```


---
### spec_path

→ String — Path to test directory (relative to root)


```ruby
def spec_path
  @spec_path
end
```


---
### spec_path=(...)

⟨value : untyped⟩
→ String — Path to test directory (relative to root)


```ruby
def spec_path=(value)
  @spec_path = value
end
```


---
### rbs_path

→ String — Path to RBS signatures directory (relative to root)


```ruby
def rbs_path
  @rbs_path
end
```


---
### rbs_path=(...)

⟨value : untyped⟩
→ String — Path to RBS signatures directory (relative to root)


```ruby
def rbs_path=(value)
  @rbs_path = value
end
```


---
### verbose

→ Boolean — Verbose output during generation


```ruby
def verbose
  @verbose
end
```


---
### verbose=(...)

⟨value : untyped⟩
→ Boolean — Verbose output during generation


```ruby
def verbose=(value)
  @verbose = value
end
```


---
### logger

→ #info — Logger for output messages


```ruby
def logger
  @logger
end
```


---
### logger=(...)

⟨value : untyped⟩
→ #info — Logger for output messages


```ruby
def logger=(value)
  @logger = value
end
```


---
### inline_source_threshold

→ Integer — Maximum body lines for inline source display.
Methods with body <= this many lines show their implementation inline.
Set to nil or 0 to disable inline source. Default: 10.


```ruby
def inline_source_threshold
  @inline_source_threshold
end
```


---
### inline_source_threshold=(...)

⟨value : untyped⟩
→ Integer — Maximum body lines for inline source display.
Methods with body <= this many lines show their implementation inline.
Set to nil or 0 to disable inline source. Default: 10.


```ruby
def inline_source_threshold=(value)
  @inline_source_threshold = value
end
```


---
### Config.new

→ Config — a new instance of Config


---
### load_file(...)
*Load configuration from a YAML file.*

⟨path : String⟩ → Path to YAML configuration file
→ Config — self


```ruby
def load_file(path)
  return self unless File.exist?(path)

  require "yaml"
  data = YAML.safe_load_file(path, symbolize_names: true)
  load_hash(data)
end
```


---
### load_hash(...)
*Load configuration from a hash.*

⟨data : Hash⟩ → Configuration values
→ Config — self


```ruby
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

→ String — Full path to source directory


```ruby
def full_source_path = File.join(root, source_path)
```


---
### full_output_path

→ String — Full path to output directory


```ruby
def full_output_path = File.join(root, output)
```


---
### full_spec_path

→ String — Full path to spec directory


```ruby
def full_spec_path = File.join(root, spec_path)
```


---
### full_rbs_path

→ String — Full path to RBS directory


```ruby
def full_rbs_path = File.join(root, rbs_path)
```
