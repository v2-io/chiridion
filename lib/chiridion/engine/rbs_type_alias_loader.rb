# frozen_string_literal: true

module Chiridion
  class Engine
    # Extracts RBS type alias definitions from generated .rbs files.
    #
    # Reads type aliases from RBS files (typically in sig/generated/) which have
    # already been properly parsed by RBS::Inline. This is more reliable than
    # re-parsing @rbs! blocks ourselves.
    #
    # RBS format is straightforward:
    #   module Namespace
    #     # Description comment
    #     type name = definition
    #   end
    #
    # @example
    #   loader = RbsTypeAliasLoader.new(true, logger, rbs_dir: "sig/generated")
    #   type_aliases = loader.load
    #   # => { "Archema" => [{ name: "attribute_value", definition: "...", ... }] }
    #
    class RbsTypeAliasLoader
      def initialize(verbose, logger, rbs_dir: nil)
        @verbose = verbose
        @logger  = logger
        @rbs_dir = rbs_dir
      end

      # Extract type aliases from generated RBS files.
      #
      # @return [Hash{String => Array<Hash>}] namespace -> array of type definitions
      def load
        type_aliases = {}
        return type_aliases unless @rbs_dir && Dir.exist?(@rbs_dir)

        rbs_files = Dir.glob(File.join(@rbs_dir, "**/*.rbs"))
        rbs_files.each do |file|
          parse_rbs_file(file, type_aliases)
        end

        count = type_aliases.values.flatten.size
        @logger.info "Extracted #{count} type aliases from #{rbs_files.size} RBS files" if @verbose && count.positive?
        type_aliases
      end

      private

      # Parse a .rbs file for type aliases.
      #
      # RBS files have a clean, well-defined format:
      #   module Foo
      #     # comment
      #     type name = definition
      #   end
      def parse_rbs_file(file, type_aliases)
        content = File.read(file)
        return unless content.include?("type ")

        expanded_file   = File.expand_path(file)
        lines           = content.lines
        namespace_stack = []
        pending_comment = nil

        lines.each_with_index do |line, idx|
          line_num = idx + 1
          stripped = line.strip

          # Track module/class context (RBS uses same syntax)
          # Reset pending_comment - comments before class/module are for that class, not types inside
          if stripped =~ /^(?:class|module)\s+([\w:]+)/
            name = Regexp.last_match(1)
            namespace_stack.push(name)
            pending_comment = nil
            next
          end

          # Track end statements
          if stripped == "end"
            namespace_stack.pop if namespace_stack.any?
            next
          end

          # Collect comments (description for next type)
          if stripped.start_with?("#")
            # Accumulate multi-line comments, preserving newlines
            comment_text    = stripped.sub(/^#\s?/, "")
            pending_comment = pending_comment ? "#{pending_comment}\n#{comment_text}" : comment_text
            next
          end

          # Skip blank lines (preserve pending_comment across blanks)
          next if stripped.empty?

          # Parse type definition
          if stripped =~ /^type\s+(\w+)\s*=\s*(.+)$/
            type_name = Regexp.last_match(1)
            type_def  = Regexp.last_match(2)

            namespace                 = namespace_stack.join("::")
            type_aliases[namespace] ||= []
            type_aliases[namespace] << {
              name:        type_name,
              definition:  type_def,
              description: pending_comment,
              file:        expanded_file,
              line:        line_num
            }
          end

          # Reset pending comment after any non-comment, non-blank line
          pending_comment = nil
        end
      end
    end
  end
end
