---
generated: 2025-12-12T17:59:26Z
title: github_linker.rb
source: lib/chiridion/engine/github_linker.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/github_linker.rb#L1
lines: 87
type: file
parent: engine
primary: Chiridion::Engine::GithubLinker
namespaces: [Chiridion::Engine::GithubLinker]
tags: [file, class]
description: Generates GitHub source links from file paths and line numbers.
github-linker-methods:
  - GithubLinker.new(repo, branch, root)
  - link(path, start_line, end_line)
  - url(path, start_line, end_line)
---

# Class: Chiridion::Engine::GithubLinker
**Extends:** Object

Generates GitHub source links from file paths and line numbers.

Parses git remote URL to extract org/repo, then constructs blob URLs
with line references for linking documentation back to source.

## Constants
### GITHUB_REMOTE_PATTERN
Pattern matching both HTTPS and SSH GitHub remote URLs:
- https://github.com/org/repo.git
- git@github.com:org/repo.git

```ruby
%r{
  (?:https://github\.com/|git@github\.com:)
  ([^/]+)/([^/]+?)(?:\.git)?$
}x
```

## Attributes / Methods
`⟨base_url : String⟩` — GitHub base URL (e.g., "https://github.com/org/repo")
`⟨branch   : String⟩` — Git branch for source links
`⟨link(…)  : String⟩` — Generate a markdown link to a source location on GitHub.
`⟨url(…)   : String⟩` — Generate just the URL (for frontmatter).

## Methods
### GithubLinker.new(...)
`⟨repo   : String = nil    ⟩` — Explicit GitHub repo (e.g., "org/repo")
`⟨branch : String = "main" ⟩` — Git branch for links
`⟨root   : String = Dir.pwd⟩` — Project root for detecting git remote
⟶ `GithubLinker            ` — A new instance of GithubLinker

#### Source
```ruby
# lib/chiridion/engine/github_linker.rb:19
def initialize(repo: nil, branch: "main", root: Dir.pwd)
  @branch   = branch
  @base_url = repo ? "https://github.com/#{repo}" : extract_github_base_url(root)
end
```

---
### link(...)
Generate a markdown link to a source location on GitHub.

`⟨path       : String       ⟩` — Project-relative file path
`⟨start_line : Integer      ⟩` — Starting line number
`⟨end_line   : Integer = nil⟩` — Ending line number (optional)
⟶ `String                   ` — Markdown link or plain text if no GitHub remote

#### Source
```ruby
# lib/chiridion/engine/github_linker.rb:30
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

`⟨path       : String       ⟩` — Project-relative file path
`⟨start_line : Integer      ⟩` — Starting line number
`⟨end_line   : Integer = nil⟩` — Ending line number (optional)
⟶ `String                   ` — GitHub URL or nil if no GitHub remote

#### Source
```ruby
# lib/chiridion/engine/github_linker.rb:44
def url(path, start_line, end_line = nil)
  return nil unless @base_url

  format_url(path, start_line, end_line)
end
```


---
**Private:** `#extract_github_base_url`:78, `#format_text`:52, `#format_url`:60
