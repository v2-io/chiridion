# frozen_string_literal: true

module Chiridion
  class Engine
    # Comprehensive semantic document model for extracted documentation.
    #
    # This module defines immutable data structures that capture ALL information
    # from YARD and RBS sources. The goal is complete semantic extraction,
    # independent of rendering concerns.
    #
    # Design principles:
    # - Capture everything, filter/format at render time
    # - Prefer explicit nil over missing keys
    # - Use typed structures (Data.define) for compile-time safety
    # - Group related data (e.g., yield info together)
    #
    # @see TODO.md for the complete tag inventory this model addresses
    module DocumentModel
      # Parameter documentation (method param or @option entry).
      #
      # @example Basic parameter
      #   ParamDoc.new(name: "id", type: "String", description: "User ID", default: nil)
      #
      # @example Optional with default
      #   ParamDoc.new(name: "limit", type: "Integer", description: "Max results", default: "10")
      ParamDoc = Data.define(
        :name,        # String - parameter name (cleaned, no sigils)
        :type,        # String? - RBS/YARD type expression
        :description, # String? - description text
        :default,     # String? - default value (as string from source)
        :prefix       # String? - "*", "**", "&" for splat/block params
      ) do
        def self.from_hash(h)
          new(
            name:        h[:name]&.to_s,
            type:        normalize_type(h[:types]),
            description: h[:text],
            default:     h[:default],
            prefix:      extract_prefix(h[:name])
          )
        end

        def self.normalize_type(types)
          return nil if types.nil? || types.empty?

          Array(types).first&.to_s
        end

        def self.extract_prefix(name)
          s = name.to_s
          return "**" if s.start_with?("**")
          return "*" if s.start_with?("*")
          return "&" if s.start_with?("&")

          nil
        end
      end

      # @option tag documentation (hash parameter options).
      OptionDoc = Data.define(
        :param_name,  # String - the hash param this option belongs to
        :key,         # String - the option key name
        :type,        # String? - option value type
        :description  # String? - description
      )

      # Block/yield documentation.
      #
      # Captures @yield, @yieldparam, and @yieldreturn together.
      YieldDoc = Data.define(
        :description,   # String? - @yield description
        :params,        # Array[ParamDoc] - @yieldparam entries
        :return_type,   # String? - @yieldreturn type
        :return_desc,   # String? - @yieldreturn description
        :block_type     # String? - RBS block signature like "^(Batch) -> void"
      )

      # Exception documentation.
      RaiseDoc = Data.define(
        :type,        # String - exception class name
        :description  # String? - when/why raised
      )

      # Return type documentation.
      ReturnDoc = Data.define(
        :type,        # String? - return type
        :description  # String? - what it returns
      )

      # Example documentation.
      ExampleDoc = Data.define(
        :name,  # String? - example name/title
        :code   # String - example code
      )

      # Cross-reference (@see tag).
      SeeDoc = Data.define(
        :target, # String - what to see (class, method, URL)
        :text    # String? - additional context
      )

      # Instance variable documentation.
      IvarDoc = Data.define(
        :name,        # String - ivar name without @
        :type,        # String? - RBS type
        :description  # String? - description
      )

      # Constant documentation.
      ConstantDoc = Data.define(
        :name,        # String - constant name
        :value,       # String? - constant value (stringified)
        :type,        # String? - RBS type if declared
        :description  # String? - docstring
      )

      # Type alias documentation.
      TypeAliasDoc = Data.define(
        :name,        # String - alias name
        :definition,  # String - RBS type definition
        :description, # String? - description
        :namespace    # String - where defined
      )

      # Method signature overload.
      OverloadDoc = Data.define(
        :signature,   # String - full RBS signature
        :description  # String? - description for this overload
      )

      # Method documentation - comprehensive capture of all method info.
      MethodDoc = Data.define(
        # Identity
        :name,              # Symbol - method name
        :scope,             # Symbol - :class or :instance
        :visibility,        # Symbol - :public, :protected, :private
        :signature,         # String - Ruby signature from YARD

        # Documentation
        :docstring,         # String? - main docstring
        :params,            # Array[ParamDoc] - parameters
        :options,           # Array[OptionDoc] - @option entries
        :returns,           # ReturnDoc? - return info
        :yields,            # YieldDoc? - block/yield info
        :raises,            # Array[RaiseDoc] - exceptions
        :examples,          # Array[ExampleDoc] - @example tags
        :notes,             # Array[String] - @note entries
        :see_also,          # Array[SeeDoc] - @see entries

        # Metadata
        :api,               # String? - @api value (private, public, internal)
        :deprecated,        # String? - deprecation message or true/"" if just tagged
        :abstract,          # bool - is abstract?
        :since,             # String? - @since version
        :todo,              # String? - @todo message

        # RBS-specific
        :rbs_signature,     # String? - full RBS signature
        :overloads,         # Array[OverloadDoc] - method overloads from RBS

        # Source
        :source,            # String? - source code
        :source_body_lines, # Integer? - body line count (for inline display threshold)
        :attr_type,         # Symbol? - :reader, :writer, :accessor if attr method
        :file,              # String? - source file
        :line,              # Integer? - line number

        # Spec integration
        :spec_examples,     # Array[Hash] - examples from specs
        :spec_behaviors     # Array[String] - behavior descriptions
      )

      # Attribute documentation (synthesized from reader/writer pairs).
      AttributeDoc = Data.define(
        :name,        # String - attribute name
        :type,        # String? - type from RBS or YARD
        :description, # String? - description
        :mode,        # Symbol - :read, :write, :read_write
        :reader,      # MethodDoc? - reader method doc
        :writer       # MethodDoc? - writer method doc
      )

      # Class or module documentation.
      NamespaceDoc = Data.define(
        # Identity
        :name,              # String - short name
        :path,              # String - full path (Foo::Bar)
        :type,              # Symbol - :class or :module
        :superclass,        # String? - superclass path (classes only)

        # Documentation
        :docstring,         # String? - main docstring
        :examples,          # Array[ExampleDoc] - @example tags
        :notes,             # Array[String] - @note entries
        :see_also,          # Array[SeeDoc] - @see entries

        # Metadata
        :api,               # String? - @api value
        :deprecated,        # String? - deprecation message
        :abstract,          # bool - is abstract?
        :since,             # String? - @since version
        :todo,              # String? - @todo message

        # Relationships
        :includes,          # Array[String] - included modules
        :extends,           # Array[String] - extended modules

        # Members
        :constants,         # Array[ConstantDoc]
        :type_aliases,      # Array[TypeAliasDoc] - local type aliases
        :ivars,             # Array[IvarDoc] - instance variables
        :attributes,        # Array[AttributeDoc] - synthesized attributes
        :methods,           # Array[MethodDoc] - public methods
        :private_methods,   # Array[MethodDoc] - private/protected (may be minimal)

        # Source
        :file,              # String? - source file
        :line,              # Integer? - start line
        :end_line,          # Integer? - end line
        :rbs_file,          # String? - corresponding RBS file

        # Spec integration
        :spec_examples,     # Hash? - class-level spec examples

        # Cross-references (populated after extraction)
        :referenced_types   # Array[TypeAliasDoc] - types used by this class
      )

      # Complete documentation structure for a project.
      ProjectDoc = Data.define(
        :title,             # String - project title
        :description,       # String? - project description
        :namespaces,        # Array[NamespaceDoc] - all documented classes/modules
        :type_aliases,      # Hash[String, Array[TypeAliasDoc]] - global type aliases
        :generated_at       # Time - generation timestamp
      ) do
        def classes = namespaces.select { |n| n.type == :class }
        def modules = namespaces.select { |n| n.type == :module }
      end
    end
  end
end
