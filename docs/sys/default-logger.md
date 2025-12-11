---
generated: 2025-12-11T22:27:44Z
title: Chiridion::DefaultLogger
type: class
source: lib/chiridion/engine.rb:280
description: Simple default logger that prints to stderr.
inherits: Object
tags: [default-logger]
aliases: [DefaultLogger]
methods: [error, info, warn]
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine.rb#L280
---

# Chiridion::DefaultLogger

Simple default logger that prints to stderr.





## Methods

### info(...)

`⟨msg⟩`


```ruby
# lib/chiridion/engine.rb : ~281
def info(msg) = Kernel.warn(msg)
```


---
### warn(...)

`⟨msg⟩`


```ruby
# lib/chiridion/engine.rb : ~282
def warn(msg) = Kernel.warn("WARNING: #{msg}")
```


---
### error(...)

`⟨msg⟩`


```ruby
# lib/chiridion/engine.rb : ~283
def error(msg) = Kernel.warn("ERROR: #{msg}")
```
