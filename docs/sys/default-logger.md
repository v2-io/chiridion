---
generated: 2025-12-10T22:33:19Z
title: Chiridion::DefaultLogger
type: class
source: lib/chiridion/engine.rb:271
description: Simple default logger that prints to stderr.
inherits: Object
tags: [default-logger]
aliases: [DefaultLogger]
methods: [error, info, warn]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine.rb#L271
---

# Chiridion::DefaultLogger

Simple default logger that prints to stderr.





## Methods

### info(...)

⟨msg : untyped⟩


```ruby
def info(msg) = Kernel.warn(msg)
```


---
### warn(...)

⟨msg : untyped⟩


```ruby
def warn(msg) = Kernel.warn("WARNING: #{msg}")
```


---
### error(...)

⟨msg : untyped⟩


```ruby
def error(msg) = Kernel.warn("ERROR: #{msg}")
```
