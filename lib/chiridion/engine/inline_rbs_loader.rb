# frozen_string_literal: true

module Chiridion
  class Engine
    # Extracts RBS type signatures from inline annotations in Ruby source.
    #
    # Supports the rbs-inline format where types are specified in comments:
    #
    #   # @rbs param: String -- description
    #   # @rbs return: Integer
    #   def method(param)
    #
    # This is the preferred way to specify types in source code, as it keeps
    # type information co-located with the code. The RbsLoader handles
    # separate sig/ files as a fallback.
    #
    # @see https://github.com/soutaro/rbs-inline
    class InlineRbsLoader
      def initialize(verbose, logger)
        @verbose = verbose
        @logger  = logger
      end

      # Extract inline RBS annotations from Ruby source files.
      #
      # @param source_files [Array<String>] Paths to Ruby files
      # @return [Array(Hash, Hash, Hash)] [signatures, rbs_file_namespaces, attr_types]
      #   - signatures: class -> method -> signature
      #   - rbs_file_namespaces: file -> [namespaces] for files with @rbs content
      #   - attr_types: class -> attr_name -> { type:, desc: } (from #: annotations or @rbs! blocks)
      def load(source_files)
        signatures           = {}
        @rbs_file_namespaces = {}
        @attr_types          = {}

        source_files.each do |file|
          next unless File.exist?(file)

          parse_file(file, signatures)
        end

        @logger.info "Extracted inline RBS from #{source_files.size} files" if @verbose && source_files.any?
        [signatures, @rbs_file_namespaces, @attr_types]
      end

      private

      def parse_file(file, signatures)
        content         = File.read(file)
        expanded_file   = File.expand_path(file)
        # Stack of [name_parts, indent_level] for tracking nested namespaces
        namespace_stack = []
        pending_rbs     = {}
        file_has_rbs    = content.include?("@rbs")
        file_namespaces = []
        in_rbs_block    = false
        # Track multi-line Struct.new/Data.define: { indent:, name: } waiting for `) do`
        pending_struct  = nil

        content.each_line.with_index do |line, _idx|
          # Track @rbs! block start
          if line =~ /^\s*#\s*@rbs!/
            in_rbs_block = true
            next
          end

          # Parse @rbs! block content for attr_accessor/reader/writer types
          if in_rbs_block
            # Track nested class declarations inside @rbs! blocks
            if line =~ /^\s*#\s+class\s+(\w+)/
              Regexp.last_match(1)
            elsif line =~ /^\s*#\s+attr_(?:accessor|reader|writer)\s+(\w+):\s*(.+)$/
              attr_name                  = Regexp.last_match(1)
              attr_type                  = Regexp.last_match(2).strip
              base_class                 = current_namespace(namespace_stack)
              # Use nested class from @rbs! block if present
              full_class                 = rbs_block_class ? "#{base_class}::#{rbs_block_class}" : base_class
              # Store as { type:, desc: } for consistency (no desc in @rbs! format)
              (@attr_types[full_class] ||= {})[attr_name] = { type: attr_type, desc: nil } unless full_class.empty?
            elsif line !~ /^\s*#/ # Non-comment line ends @rbs! block
              in_rbs_block    = false
              nil
            end
          end

          # Parse Struct.new/Data.define member annotations: :name, #: Type -- description
          if pending_struct && line =~ /:(\w+),?\s*#:\s*(.+)$/
            attr_name                           = Regexp.last_match(1)
            type_and_desc                       = Regexp.last_match(2).strip
            type, desc                          = type_and_desc.split(/\s+--\s+/, 2)
            pending_struct[:members]          ||= {}
            pending_struct[:members][attr_name] = { type: type.strip, desc: capitalize_first(desc) }
          end
          # Track class/module context - push onto namespace stack with indentation
          if line =~ /^(\s*)(?:class|module)\s+([\w:]+)/
            class_indent                = Regexp.last_match(1).length
            name                        = Regexp.last_match(2)
            # Handle inline fully-qualified names like "class Foo::Bar"
            name_parts                  = name.split("::")
            namespace_stack.push([name_parts, class_indent])
            current_class               = current_namespace(namespace_stack)
            signatures[current_class] ||= {}
            # Track namespaces this file contributes to (for @rbs change detection)
            file_namespaces << current_class if file_has_rbs
            pending_rbs                 = {}
          end

          # Track Data.define/Struct.new blocks as pseudo-classes
          # Single-line: ConstName = Data.define(...) do  or  ConstName = Struct.new(...) do
          if line =~ /^(\s*)([\w:]+)\s*=\s*(?:Data\.define|Struct\.new)\b.*\bdo\s*(?:#.*)?$/
            block_indent                = Regexp.last_match(1).length
            name                        = Regexp.last_match(2)
            name_parts                  = name.split("::")
            namespace_stack.push([name_parts, block_indent])
            current_class               = current_namespace(namespace_stack)
            signatures[current_class] ||= {}
            pending_rbs                 = {}
          # Multi-line start: ConstName = Data.define( or ConstName = Struct.new(
          # We'll complete this when we see `) do` later
          elsif line =~ /^(\s*)([\w:]+)\s*=\s*(?:Data\.define|Struct\.new)\s*\(/
            pending_struct = { indent: Regexp.last_match(1).length, name: Regexp.last_match(2) }
          # Multi-line completion: ) do (possibly with keyword args before)
          elsif pending_struct && line =~ /\)\s*do\s*(?:#.*)?$/
            name_parts                  = pending_struct[:name].split("::")
            namespace_stack.push([name_parts, pending_struct[:indent]])
            current_class               = current_namespace(namespace_stack)
            signatures[current_class] ||= {}
            # Apply accumulated member types to @attr_types
            if pending_struct[:members]&.any?
              @attr_types[current_class] ||= {}
              @attr_types[current_class].merge!(pending_struct[:members])
            end
            pending_rbs                 = {}
            pending_struct              = nil
          end

          # Track `end` statements - pop if indentation matches a namespace
          if line =~ /^(\s*)end\s*(?:#.*)?$/
            end_indent = Regexp.last_match(1).length
            # Pop all namespaces at this indentation level
            namespace_stack.pop while namespace_stack.any? && namespace_stack.last[1] == end_indent
          end

          # Collect @rbs annotations
          if line =~ /^\s*#\s*@rbs\s+(\w+):\s*(.+)$/
            key              = Regexp.last_match(1)
            value            = Regexp.last_match(2).strip
            # Handle "-- description" suffix
            type, desc       = value.split(" -- ", 2)
            pending_rbs[key] = { type: type.strip, desc: capitalize_first(desc) }
          end

          # When we hit a method definition, apply pending RBS
          # Matches: def foo, def foo?, def foo!, def self.foo, def [], def []=, def +, etc.
          current_class = current_namespace(namespace_stack)
          if !current_class.empty? && line =~ %r{^\s*def\s+(?:self\.)?(\w+[?!=]?|\[\]=?|[+\-*/%&|^<>=!~]+)}
            method_name = Regexp.last_match(1)
            if pending_rbs.any?
              signatures[current_class][method_name] = build_signature(pending_rbs)
              pending_rbs                            = {}
            end
          end

          # Reset pending RBS on blank lines or non-comment lines (but not on def lines)
          is_comment = line.strip.start_with?("#")
          is_def     = line =~ /^\s*def\s/
          is_blank   = line.strip.empty?

          pending_rbs = {} if (is_blank || (!is_comment && !is_def)) && !is_def
        end

        # Store file -> namespaces mapping for files with @rbs content
        @rbs_file_namespaces[expanded_file] = file_namespaces.uniq if file_namespaces.any?
      end

      def current_namespace(stack) = stack.flat_map { |parts, _indent| parts }.join("::")

      def capitalize_first(str)
        return nil if str.nil? || str.strip.empty?

        s = str.strip
        s[0].upcase + s[1..]
      end

      def build_signature(rbs_data)
        params  = {}
        returns = rbs_data.delete("return")

        # Each value is now { type: "...", desc: "..." }
        rbs_data.each do |name, data|
          params[name] = data
        end

        # Build full signature string using just the types
        param_str   = params.map { |name, data| "#{data[:type]} #{name}" }.join(", ")
        return_type = returns&.dig(:type) || "void"
        full        = "(#{param_str}) -> #{return_type}"

        {
          full:    full,
          params:  params,  # { name => { type:, desc: } }
          returns: returns  # { type:, desc: } or nil
        }
      end
    end
  end
end
