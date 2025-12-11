---
generated: 2025-12-11T22:51:37Z
title: Chiridion::Engine::GithubLinker
type: class
source: lib/chiridion/engine/github_linker.rb:9
description: Generates GitHub source links from file paths and line numbers.
inherits: Object
parent: "[[engine|Chiridion::Engine]]"
tags: [engine, github-linker]
aliases: [GithubLinker]
constants: [GITHUB_REMOTE_PATTERN]
methods: [base_url, branch, initialize, link, url]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/github_linker.rb#L9
---

# Chiridion::Engine::GithubLinker

Generates GitHub source links from file paths and line numbers.

Parses git remote URL to extract org/repo, then constructs blob URLs
with line references for linking documentation back to source.

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `GITHUB_REMOTE_PATTERN` | *(see below)* | Pattern matching both HTTPS and SSH GitHub remote URLs: - https://github.com/org/repo.git - git@github.com:org/repo.git |



### GITHUB_REMOTE_PATTERN


Pattern matching both HTTPS and SSH GitHub remote URLs:
- https://github.com/org/repo.git
- git@github.com:org/repo.git

```ruby
GITHUB_REMOTE_PATTERN = %r{
  (?:https://github\.com/|git@github\.com:)
  ([^/]+)/([^/]+?)(?:\.git)?$
}x
```



## Attributes

`⟨base_url : String⟩` — (Read) GitHub base URL (e.g., "https://github.com/org/repo")
`⟨branch   : String⟩` — (Read) Git branch for source links

## Methods

### GithubLinker.new(...)

`⟨repo   = nil⟩    `
`⟨branch = "main"⟩ `
`⟨root   = Dir.pwd⟩`
⟶ `GithubLinker    ` — A new instance of GithubLinker


```ruby
# lib/chiridion/engine/github_linker.rb : ~19
def initialize(repo: nil, branch: "main", root: Dir.pwd)
  @branch   = branch
  @base_url = repo ? "https://github.com/#{repo}" : extract_github_base_url(root)
end
```


---
### link(...)
Generate a markdown link to a source location on GitHub.

`⟨path       : String⟩       ` — Project-relative file path
`⟨start_line : Integer⟩      ` — Starting line number
`⟨end_line   : Integer = nil⟩` — Ending line number (optional)
⟶ `String                    ` — Markdown link or plain text if no GitHub remote


```ruby
# lib/chiridion/engine/github_linker.rb : ~30
def link(path, start_line, end_line = nil)
  text = format_text(path, start_line, end_line)
  return "`#{text}`" unless @base_url

  url = format_url(path, start_line, end_line)
  "[#{text}](#{url})"
end
```


---
### url(...)
Generate just the URL (for frontmatter).

`⟨path       : String⟩       ` — Project-relative file path
`⟨start_line : Integer⟩      ` — Starting line number
`⟨end_line   : Integer = nil⟩` — Ending line number (optional)
⟶ `String                    ` — GitHub URL or nil if no GitHub remote


```ruby
# lib/chiridion/engine/github_linker.rb : ~44
def url(path, start_line, end_line = nil)
  return nil unless @base_url

  format_url(path, start_line, end_line)
end
```

---

**Private:** `#extract_github_base_url`:78, `#format_text`:52, `#format_url`:60
