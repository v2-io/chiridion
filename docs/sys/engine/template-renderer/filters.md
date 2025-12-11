---
generated: 2025-12-11T22:34:06Z
title: Chiridion::Engine::TemplateRenderer::Filters
type: module
source: lib/chiridion/engine/template_renderer.rb:19
description: Custom Liquid filters for documentation rendering.
parent: "[[engine/template-renderer|Chiridion::Engine::TemplateRenderer]]"
tags: [engine, template-renderer, filters]
aliases: [Filters]
methods: [escape_pipes, kebab_case, strip_newlines]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/template_renderer.rb#L19
---

# Chiridion::Engine::TemplateRenderer::Filters

Custom Liquid filters for documentation rendering.





## Methods

### escape_pipes(...)
Escape pipe characters for markdown table cells.

`⟨input⟩`


```ruby
# lib/chiridion/engine/template_renderer.rb : ~21
def escape_pipes(input)
  return "" if input.nil?

  input.to_s.gsub("|", "\\|")
end
```


---
### strip_newlines(...)
Remove newlines for single-line table cells.

`⟨input⟩`


```ruby
# lib/chiridion/engine/template_renderer.rb : ~28
def strip_newlines(input)
  return "" if input.nil?

  input.to_s.gsub(/\s*\n\s*/, " ").strip
end
```


---
### kebab_case(...)
Convert to kebab case for file paths.

`⟨input⟩`


```ruby
# lib/chiridion/engine/template_renderer.rb : ~35
def kebab_case(input)
  return "" if input.nil?

  input.to_s
       .gsub(/([A-Za-z])([vV]\d+)/, '\1-\2')
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
       .gsub(/([a-z\d])([A-Z])/, '\1-\2')
       .downcase
end
```
