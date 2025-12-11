# Chiridion TODO

Documentation audit and enhancement roadmap based on analysis of archema and dry-rbs codebases.

## Critical: Data Being Discarded

### 1. ~~`@rbs` Descriptions~~ ✅ Fixed in v0.2.3

**Solution (implemented):**
- `InlineRbsLoader` now stores `{ type: type.strip, desc: capitalize_first(desc) }`
- `TypeMerger#merge_description` uses "longer wins" policy, tie goes to RBS
- First letter of descriptions is capitalized

---

### 2. `@option` Tags (52 occurrences in archema)

**Problem:** YARD `@option` tags for hash parameters are completely ignored.

**Example from archema:**
```ruby
# @param options [Hash] transaction options
# @option options [Symbol] :isolation isolation level
# @option options [Boolean] :savepoint use savepoint for nested transactions
```

**Currently:** Only "@param options [Hash] transaction options" appears in docs.
The `:isolation` and `:savepoint` details are invisible.

**Fix needed:**
- Extract `@option` tags in Extractor: `meth.tags(:option)`
- Associate with parent param
- Render as sub-list or table under the param

---

### 3. `@yield` / `@yieldparam` / `@yieldreturn` (42+ occurrences)

**Problem:** Block documentation completely ignored.

**Example:**
```ruby
# @yield DSL block for defining attributes
# @yieldparam [AttributesDSL] dsl context
# @yieldreturn [void]
def attributes(&block)
```

**Fix needed:**
- Extract in Extractor: `meth.tags(:yield)`, `meth.tags(:yieldparam)`, `meth.tags(:yieldreturn)`
- Render as "Block parameters:" section in method docs

---

## High Value: Metadata Being Ignored

### 4. `@api` Tag (22 occurrences - all `private`)

**Problem:** Methods marked `@api private` are implementation details but shown same as public API.

**Use cases:**
- Filter from main docs, show in "Internal" section
- De-emphasize visually
- Use for method grouping/importance ranking

**Fix needed:**
- Extract in Extractor: `meth.tag(:api)&.text`
- Pass to Renderer for grouping decisions

---

### 5. `@raise` / `@rbs raises` (36 combined)

**Problem:** Exception contracts invisible.

**Example:**
```ruby
# @raise [ValidationError] if attributes invalid
# @rbs raises: Archema::ValidationError
```

**Fix needed:**
- YARD: `meth.tags(:raise)`
- RBS: Already parsing `@rbs raises` but not surfacing
- Render as "Raises:" section

---

### 6. `@deprecated` (7 in dry-rbs)

**Problem:** Migration warnings lost.

**Fix needed:**
- Extract: `meth.tag(:deprecated)&.text`
- Render prominently (banner or badge)

---

### 7. `@note` (2 occurrences)

**Problem:** Important author caveats lost.

**Fix needed:**
- Extract: `meth.tags(:note)`
- Render as callout/admonition

---

### 8. `@abstract` (3 occurrences)

**Problem:** Interface contracts not marked.

**Fix needed:**
- Extract: `obj.tag(:abstract)` on class/method
- Render as badge or section header

---

## Medium Value: RBS Features

### 9. Instance Variable Types (`@rbs @name: Type`) - 173 occurrences

**Problem:** Internal state documentation invisible.

**Example:**
```ruby
# @rbs @name: Symbol
# @rbs @type: Dry::Types::Type
attr_reader :name, :type
```

**Fix needed:**
- Parse `@rbs @varname:` pattern in InlineRbsLoader
- Surface in class documentation (optional section)

---

### 10. Block Signatures (`^(Batch) -> void`)

**Problem:** Callback type signatures not highlighted.

**Example:**
```ruby
# @rbs &block: ^(Batch) -> void
def on_commit(&block)
```

**Fix needed:**
- Parse block param types specially
- Render with readable format: "Block: (Batch) → void"

---

### 11. Method Overloads

**Problem:** Only one signature shown for polymorphic methods.

**Example from dry-rbs:**
```rbs
def call: (?untyped input) -> untyped
        | [T] (untyped input) { (untyped) -> T } -> (untyped | T)
```

**Fix needed:**
- Parse multiple signatures from RBS
- Render all overloads

---

## Cleanup: False Alarm Warnings

### Suppress Known-Equivalent Type Mismatches

**Problem:** TypeMerger warns on syntactically different but semantically equivalent types.

**False alarms to suppress:**

1. **Union syntax:** YARD `Symbol, Class, nil` vs RBS `Symbol | Class | nil`
   - These are identical semantically, just different notation

2. **`initialize` return type:** YARD says `ClassName`, RBS says `void`
   - YARD convention: `@return [ClassName]` on initialize (what `new` returns)
   - RBS convention: `def initialize: () -> void` (initialize itself returns nil)
   - Both are "correct" in their respective systems

**Fix needed:**
- Normalize union types before comparison (sort, strip whitespace, treat `,` and `|` as equivalent)
- Special-case `initialize`: don't warn if YARD return matches class name and RBS says `void`

---

## Lower Priority

### 12. `@since` - Version tracking
### 13. `@type self:` - Steep type narrowing (probably fine to ignore)
### 14. `@overload` - YARD method overloads
### 15. `@todo` - Might be useful for agents to know

---

## Tag Inventory (from archema + dry-rbs audit)

| Tag | Count | Status |
|-----|------:|--------|
| `@rbs [param]` | 1,130 | ✅ Types and descriptions captured |
| `@rbs return` | 952 | ✅ Captured |
| `@param` | 332 | ✅ Captured |
| `@example` | 319 | ✅ Captured |
| `@return` | 265 | ✅ Captured |
| `@rbs @[ivar]` | 173 | ❌ Ignored |
| `@option` | 52 | ❌ Ignored |
| `@yield` | 42 | ❌ Ignored |
| `@rbs raises` | 28 | ❌ Ignored |
| `@api` | 22 | ❌ Ignored |
| `@rbs!` | 22 | ⚠️ Partial |
| `@type` | 17 | ❌ Ignored (Steep) |
| `@rbs skip` | 9 | ✅ Respected |
| `@raise` | 8 | ❌ Ignored |
| `@deprecated` | 7 | ❌ Ignored |
| `@abstract` | 3 | ❌ Ignored |
| `@note` | 2 | ❌ Ignored |
| `@yieldreturn` | 2 | ❌ Ignored |

---

## Recently Completed (v0.2.3)

- [x] `@rbs` descriptions now captured (1,130 occurrences in archema)
- [x] Description merge policy: longer wins, tie to RBS (co-located)
- [x] First letter of @rbs descriptions capitalized

## v0.2.2

- [x] Inline source moved to end of method docs
- [x] Location comment: `# lib/path/file.rb : ~42`
- [x] attr_* condensed to one-liners: `def foo = @foo`
- [x] Attribute summary table with r/w/rw mode
- [x] Omit `: untyped` from param display
- [x] Private methods summary with line numbers

---

## Implementation Notes

### Description Merge Policy

When both `@rbs` and `@param` have descriptions, use the longer one:

```ruby
def merge_description(yard_desc, rbs_desc)
  return rbs_desc if yard_desc.to_s.empty?
  return yard_desc if rbs_desc.to_s.empty?

  # Longer description wins; tie goes to RBS (co-located)
  rbs_desc.length >= yard_desc.length ? rbs_desc : yard_desc
end
```

This naturally handles substring cases (the superset is always longer).

### Files to Modify

1. `lib/chiridion/engine/inline_rbs_loader.rb` - Store @rbs descriptions
2. `lib/chiridion/engine/type_merger.rb` - Merge descriptions with policy
3. `lib/chiridion/engine/extractor.rb` - Extract @option, @yield, @raise, @api, etc.
4. `lib/chiridion/engine/renderer.rb` - Render new sections
5. `templates/method.liquid` - Add templates for new sections
