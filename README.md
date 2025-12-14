# Chiridion

Agent-oriented documentation generator for Ruby projects.

**Chiridion** (from Greek χειρίδιον, "handbook" — the diminutive of χείρ "hand") generates documentation optimized for AI agents and LLMs working with Ruby codebases.

## Why Agent-Oriented Documentation?

Traditional documentation is written for human developers reading in browsers. Agent-oriented documentation is optimized for LLMs processing in context windows:

- **Structured frontmatter** with navigation metadata for programmatic traversal
- **Explicit type information** from RBS (not just prose descriptions)
- **Cross-reference wikilinks** that can be followed programmatically
- **Compact method signatures** that maximize information density

## Features

- **YARD Integration** — Extracts docstrings, @param, @return, @example tags
- **RBS Authority** — RBS type signatures (inline or in sig/) are authoritative over YARD
- **Inline RBS Preferred** — Supports `@rbs` inline annotations via rbs-inline
- **Spec Examples** — Extracts usage examples from RSpec files
- **Wikilinks** — Obsidian-compatible `[[Class::Name]]` cross-references
- **Drift Detection** — CI mode to ensure docs stay in sync with code

## Installation

Add to your Gemfile:

```ruby
gem "chiridion", path: "~/src/chiridion"  # Local development
```

## Usage

### Configuration

```ruby
Chiridion.configure do |config|
  config.source_path = "lib/myproject"
  config.output = "docs/sys"
  config.namespace_filter = "MyProject::"
  config.github_repo = "user/repo"
  config.include_specs = true
end
```

### Generate Documentation

```ruby
Chiridion.refresh
```

Or with explicit paths:

```ruby
engine = Chiridion::Engine.new(
  paths: ['lib/myproject'],
  output: 'docs/sys',
  namespace_filter: 'MyProject::'
)
engine.refresh
```

### Check for Drift (CI)

```ruby
Chiridion.check  # Exits with code 1 if drift detected
```

## Inline RBS (Preferred)

Chiridion prioritizes inline RBS annotations over separate sig/ files:

```ruby
class Calculator
  # @rbs a: Integer -- first operand
  # @rbs b: Integer -- second operand
  # @rbs return: Integer
  def add(a, b)
    a + b
  end
end
```

This keeps types co-located with code and is the recommended approach. Separate `sig/*.rbs` files are supported as a fallback.

## Output Format

Generated markdown includes:

```yaml
---
generated: 2024-12-09 10:30 UTC
source: lib/myproject/calculator.rb:10-25
source_url: https://github.com/user/repo/blob/main/lib/myproject/calculator.rb#L10
type: class
parent: Object
---

# MyProject::Calculator

Calculator for basic arithmetic operations.

## Methods

### `#add`

```rbs
(Integer a, Integer b) -> Integer
```

Adds two integers.

**Parameters:**
- `a` (`Integer`) first operand
- `b` (`Integer`) second operand

**Returns:** `Integer`
```

## Integration with Projects

### Archema

```ruby
# Gemfile
gem "chiridion", path: "~/src/chiridion"

# Configure in tasks/docs.rb
Chiridion.configure do |config|
  config.namespace_filter = "Archema::"
  config.output = "docs/sys"
end
```

### devex Integration

Create a `tools/docs.rb`:

```ruby
# frozen_string_literal: true

desc "Documentation generation tasks"

tool "refresh" do
  desc "Regenerate API documentation"

  def run
    require_relative "../lib/myproject"

    Chiridion.configure do |c|
      c.source_path      = "lib/myproject"
      c.output           = "docs/sys"
      c.namespace_filter = "MyProject::"
      c.verbose          = verbose?  # Uses global -v flag
    end
    Chiridion.refresh
  end
end

tool "check" do
  desc "Check for documentation drift (CI mode)"

  def run
    Chiridion.check
  end
end
```

Then run with `dx docs refresh` or `dx docs check`.

## Development

Chiridion uses itself to generate its own API documentation (dogfooding). The generated docs live in `docs/sys/`.

```bash
# Run tests
dx test

# Lint
dx lint

# Regenerate Chiridion's own documentation
dx docs refresh

# Verbose output
dx -v docs refresh

# Check for drift (CI mode - exits 1 if docs are out of sync)
dx docs check
```

This serves as both a live integration test and a reference for the output format.

## Name Origin

"Chiridion" is the Greek word for a small handbook or manual — appropriate for a tool that generates compact, structured documentation for AI assistants to reference.

## License

MIT
