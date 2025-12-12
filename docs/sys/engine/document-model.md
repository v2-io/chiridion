---
generated: 2025-12-12T17:59:26Z
title: document_model.rb
source: lib/chiridion/engine/document_model.rb
source_url: https://github.com/v2-io/chiridion/blob/main/lib/chiridion/engine/document_model.rb#L1
lines: 299
type: file
parent: engine
primary: Chiridion::Engine::DocumentModel
namespaces:
  - Chiridion::Engine::DocumentModel
  - Chiridion::Engine::DocumentModel::AttributeDoc
  - Chiridion::Engine::DocumentModel::ConstantDoc
  - Chiridion::Engine::DocumentModel::ExampleDoc
  - Chiridion::Engine::DocumentModel::FileDoc
  - Chiridion::Engine::DocumentModel::IvarDoc
  - Chiridion::Engine::DocumentModel::MethodDoc
  - Chiridion::Engine::DocumentModel::NamespaceDoc
  - Chiridion::Engine::DocumentModel::OptionDoc
  - Chiridion::Engine::DocumentModel::OverloadDoc
  - Chiridion::Engine::DocumentModel::ParamDoc
  - Chiridion::Engine::DocumentModel::ProjectDoc
  - Chiridion::Engine::DocumentModel::RaiseDoc
  - Chiridion::Engine::DocumentModel::ReturnDoc
  - Chiridion::Engine::DocumentModel::SeeDoc
  - Chiridion::Engine::DocumentModel::TypeAliasDoc
  - Chiridion::Engine::DocumentModel::YieldDoc
tags: [file, module, class]
description: Comprehensive semantic document model for extracted documentation.
file-doc-methods: [classes, dirname, filename, modules, primary_namespace]
param-doc-methods:
  - ParamDoc.extract_prefix(name)
  - ParamDoc.from_hash(h)
  - ParamDoc.normalize_type(types)
project-doc-methods: [classes, modules]
---

# Module: Chiridion::Engine::DocumentModel
Comprehensive semantic document model for extracted documentation.

This module defines immutable data structures that capture ALL information
from YARD and RBS sources. The goal is complete semantic extraction,
independent of rendering concerns.

Design principles:
- Capture everything, filter/format at render time
- Prefer explicit nil over missing keys
- Use typed structures (Data.define) for compile-time safety
- Group related data (e.g., yield info together)

**See also:** TODO.md (for the complete tag inventory this model addresses)


---
# Class: Chiridion::Engine::DocumentModel::AttributeDoc
**Extends:** Data

Attribute documentation (synthesized from reader/writer pairs).

## Attributes / Methods
`⟨description : Object⟩` — The current value of description
`⟨mode        : Object⟩` — The current value of mode
`⟨name        : Object⟩` — The current value of name
`⟨reader      : Object⟩` — The current value of reader
`⟨type        : Object⟩` — The current value of type
`⟨writer      : Object⟩` — The current value of writer


---
# Class: Chiridion::Engine::DocumentModel::ConstantDoc
**Extends:** Data

Constant documentation.

## Attributes / Methods
`⟨description : Object⟩` — The current value of description
`⟨name        : Object⟩` — The current value of name
`⟨type        : Object⟩` — The current value of type
`⟨value       : Object⟩` — The current value of value


---
# Class: Chiridion::Engine::DocumentModel::ExampleDoc
**Extends:** Data

Example documentation.

## Attributes / Methods
`⟨code : Object⟩` — The current value of code
`⟨name : Object⟩` — The current value of name


---
# Class: Chiridion::Engine::DocumentModel::FileDoc
**Extends:** Data

Documentation for a single source file.

Groups all namespaces (classes/modules) defined in one Ruby file.
This is the primary unit for per-file documentation output.

## Attributes / Methods
`⟨line_count        : Object⟩` — The current value of line_count
`⟨namespaces        : Object⟩` — The current value of namespaces
`⟨path              : Object⟩` — The current value of path
`⟨type_aliases      : Object⟩` — The current value of type_aliases
`⟨classes                   ⟩`
`⟨dirname                   ⟩` — Directory portion (e.g., "lib/archema")
`⟨filename                  ⟩` — Short filename for display (e.g., "attributes.rb")
`⟨modules                   ⟩`
`⟨primary_namespace         ⟩` — Main namespace - the one that best represents this file's purpose.

## Methods
### classes
#### Source
```ruby
# lib/chiridion/engine/document_model.rb:281
def classes = namespaces.select { |n| n.type == :class }
```

---
### dirname
Directory portion (e.g., "lib/archema")

#### Source
```ruby
# lib/chiridion/engine/document_model.rb:243
def dirname = File.dirname(path)
```

---
### filename
Short filename for display (e.g., "attributes.rb")

#### Source
```ruby
# lib/chiridion/engine/document_model.rb:240
def filename = File.basename(path)
```

---
### modules
#### Source
```ruby
# lib/chiridion/engine/document_model.rb:282
def modules = namespaces.select { |n| n.type == :module }
```

---
### primary_namespace
Main namespace - the one that best represents this file's purpose.

Selection order:
1. Namespace whose name matches filename (query.rb -> Query)
2. Module (often the container for nested classes)
3. Shortest path (top-level namespace)
4. Most content as tiebreaker


---
# Class: Chiridion::Engine::DocumentModel::IvarDoc
**Extends:** Data

Instance variable documentation.

## Attributes / Methods
`⟨description : Object⟩` — The current value of description
`⟨name        : Object⟩` — The current value of name
`⟨type        : Object⟩` — The current value of type


---
# Class: Chiridion::Engine::DocumentModel::MethodDoc
**Extends:** Data

Method documentation - comprehensive capture of all method info.

## Attributes / Methods
`⟨abstract          : Object⟩` — The current value of abstract
`⟨api               : Object⟩` — The current value of api
`⟨attr_type         : Object⟩` — The current value of attr_type
`⟨deprecated        : Object⟩` — The current value of deprecated
`⟨docstring         : Object⟩` — The current value of docstring
`⟨examples          : Object⟩` — The current value of examples
`⟨file              : Object⟩` — The current value of file
`⟨line              : Object⟩` — The current value of line
`⟨name              : Object⟩` — The current value of name
`⟨notes             : Object⟩` — The current value of notes
`⟨options           : Object⟩` — The current value of options
`⟨overloads         : Object⟩` — The current value of overloads
`⟨params            : Object⟩` — The current value of params
`⟨raises            : Object⟩` — The current value of raises
`⟨rbs_signature     : Object⟩` — The current value of rbs_signature
`⟨returns           : Object⟩` — The current value of returns
`⟨scope             : Object⟩` — The current value of scope
`⟨see_also          : Object⟩` — The current value of see_also
`⟨signature         : Object⟩` — The current value of signature
`⟨since             : Object⟩` — The current value of since
`⟨source            : Object⟩` — The current value of source
`⟨source_body_lines : Object⟩` — The current value of source_body_lines
`⟨spec_behaviors    : Object⟩` — The current value of spec_behaviors
`⟨spec_examples     : Object⟩` — The current value of spec_examples
`⟨todo              : Object⟩` — The current value of todo
`⟨visibility        : Object⟩` — The current value of visibility
`⟨yields            : Object⟩` — The current value of yields


---
# Class: Chiridion::Engine::DocumentModel::NamespaceDoc
**Extends:** Data

Class or module documentation.

## Attributes / Methods
`⟨abstract         : Object⟩` — The current value of abstract
`⟨api              : Object⟩` — The current value of api
`⟨attributes       : Object⟩` — The current value of attributes
`⟨constants        : Object⟩` — The current value of constants
`⟨deprecated       : Object⟩` — The current value of deprecated
`⟨docstring        : Object⟩` — The current value of docstring
`⟨end_line         : Object⟩` — The current value of end_line
`⟨examples         : Object⟩` — The current value of examples
`⟨extends          : Object⟩` — The current value of extends
`⟨file             : Object⟩` — The current value of file
`⟨includes         : Object⟩` — The current value of includes
`⟨ivars            : Object⟩` — The current value of ivars
`⟨line             : Object⟩` — The current value of line
`⟨methods          : Object⟩` — The current value of methods
`⟨name             : Object⟩` — The current value of name
`⟨notes            : Object⟩` — The current value of notes
`⟨path             : Object⟩` — The current value of path
`⟨private_methods  : Object⟩` — The current value of private_methods
`⟨rbs_file         : Object⟩` — The current value of rbs_file
`⟨referenced_types : Object⟩` — The current value of referenced_types
`⟨see_also         : Object⟩` — The current value of see_also
`⟨since            : Object⟩` — The current value of since
`⟨spec_examples    : Object⟩` — The current value of spec_examples
`⟨superclass       : Object⟩` — The current value of superclass
`⟨todo             : Object⟩` — The current value of todo
`⟨type             : Object⟩` — The current value of type
`⟨type_aliases     : Object⟩` — The current value of type_aliases


---
# Class: Chiridion::Engine::DocumentModel::OptionDoc
**Extends:** Data

## Attributes / Methods
`⟨description : Object⟩` — The current value of description
`⟨key         : Object⟩` — The current value of key
`⟨param_name  : Object⟩` — The current value of param_name
`⟨type        : Object⟩` — The current value of type


---
# Class: Chiridion::Engine::DocumentModel::OverloadDoc
**Extends:** Data

Method signature overload.

## Attributes / Methods
`⟨description : Object⟩` — The current value of description
`⟨signature   : Object⟩` — The current value of signature


---
# Class: Chiridion::Engine::DocumentModel::ParamDoc
**Extends:** Data

Parameter documentation (method param or @option entry).

### Example
**Basic parameter**

```ruby
ParamDoc.new(name: "id", type: "String", description: "User ID", default: nil)
```

**Optional with default**

```ruby
ParamDoc.new(name: "limit", type: "Integer", description: "Max results", default: "10")
```

## Attributes / Methods
`⟨default           : Object⟩` — The current value of default
`⟨description       : Object⟩` — The current value of description
`⟨name              : Object⟩` — The current value of name
`⟨prefix            : Object⟩` — The current value of prefix
`⟨type              : Object⟩` — The current value of type
`⟨extract_prefix(…)         ⟩`
`⟨from_hash(…)              ⟩`
`⟨normalize_type(…)         ⟩`

## Methods
### ParamDoc.extract_prefix(...)
`⟨name⟩`

#### Source
```ruby
# lib/chiridion/engine/document_model.rb:49
def self.extract_prefix(name)
  s = name.to_s
  return "**" if s.start_with?("**")
  return "*" if s.start_with?("*")
  return "&" if s.start_with?("&")

  nil
end
```

---
### ParamDoc.from_hash(...)
`⟨h⟩`

#### Source
```ruby
# lib/chiridion/engine/document_model.rb:33
def self.from_hash(h)
  new(
    name:        h[:name]&.to_s,
    type:        normalize_type(h[:types]),
    description: h[:text],
    default:     h[:default],
    prefix:      extract_prefix(h[:name])
  )
end
```

---
### ParamDoc.normalize_type(...)
`⟨types⟩`

#### Source
```ruby
# lib/chiridion/engine/document_model.rb:43
def self.normalize_type(types)
  return nil if types.nil? || types.empty?

  Array(types).first&.to_s
end
```


---
# Class: Chiridion::Engine::DocumentModel::ProjectDoc
**Extends:** Data

Complete documentation structure for a project.

## Attributes / Methods
`⟨description  : Object⟩` — The current value of description
`⟨files        : Object⟩` — The current value of files
`⟨generated_at : Object⟩` — The current value of generated_at
`⟨namespaces   : Object⟩` — The current value of namespaces
`⟨title        : Object⟩` — The current value of title
`⟨type_aliases : Object⟩` — The current value of type_aliases
`⟨classes              ⟩`
`⟨modules              ⟩`

## Methods
### classes
#### Source
```ruby
# lib/chiridion/engine/document_model.rb:294
def classes = namespaces.select { |n| n.type == :class }
```

---
### modules
#### Source
```ruby
# lib/chiridion/engine/document_model.rb:295
def modules = namespaces.select { |n| n.type == :module }
```


---
# Class: Chiridion::Engine::DocumentModel::RaiseDoc
**Extends:** Data

Exception documentation.

## Attributes / Methods
`⟨description : Object⟩` — The current value of description
`⟨type        : Object⟩` — The current value of type


---
# Class: Chiridion::Engine::DocumentModel::ReturnDoc
**Extends:** Data

Return type documentation.

## Attributes / Methods
`⟨description : Object⟩` — The current value of description
`⟨type        : Object⟩` — The current value of type


---
# Class: Chiridion::Engine::DocumentModel::SeeDoc
**Extends:** Data

Cross-reference (@see tag).

## Attributes / Methods
`⟨target : Object⟩` — The current value of target
`⟨text   : Object⟩` — The current value of text


---
# Class: Chiridion::Engine::DocumentModel::TypeAliasDoc
**Extends:** Data

Type alias documentation.

## Attributes / Methods
`⟨definition  : Object⟩` — The current value of definition
`⟨description : Object⟩` — The current value of description
`⟨name        : Object⟩` — The current value of name
`⟨namespace   : Object⟩` — The current value of namespace


---
# Class: Chiridion::Engine::DocumentModel::YieldDoc
**Extends:** Data

Block/yield documentation.

Captures @yield, @yieldparam, and @yieldreturn together.

## Attributes / Methods
`⟨block_type  : Object⟩` — The current value of block_type
`⟨description : Object⟩` — The current value of description
`⟨params      : Object⟩` — The current value of params
`⟨return_desc : Object⟩` — The current value of return_desc
`⟨return_type : Object⟩` — The current value of return_type
