# frozen_string_literal: true

module Chiridion
  class Engine
    # Comprehensive loader for RBS::Inline-generated .rbs files.
    #
    # Unlike the simpler RbsLoader, this extracts ALL available information
    # from generated RBS files:
    #
    # - Method signatures with parameter types and return types
    # - Instance variable declarations (@name: Type)
    # - Attribute declarations (attr_reader name: Type)
    # - Type aliases (type name = definition)
    # - Class/module structure with comments
    #
    # The generated RBS files are authoritative - they've been properly parsed
    # by rbs-inline from the source annotations. We just need to read them.
    #
    # @example
    #   loader = GeneratedRbsLoader.new(verbose: true, logger: logger)
    #   data = loader.load("sig/generated")
    #   # => { signatures: {...}, ivars: {...}, attrs: {...}, type_aliases: {...} }
    #
    class GeneratedRbsLoader
      # Result structure from loading.
      Result = Data.define(
        :signatures,    # Hash[class_path => Hash[method_name => signature_data]]
        :ivars,         # Hash[class_path => Hash[ivar_name => { type:, desc: }]]
        :attrs,         # Hash[class_path => Hash[attr_name => { type:, desc: }]]
        :type_aliases,  # Hash[namespace => Array[{ name:, definition:, description: }]]
        :overloads      # Hash[class_path => Hash[method_name => Array[signature_strings]]]
      )

      def initialize(verbose: false, logger: nil)
        @verbose = verbose
        @logger  = logger
      end

      # Load all data from generated RBS directory.
      #
      # @param rbs_dir [String] Path to generated RBS directory (e.g., "sig/generated")
      # @return [Result] All extracted data
      def load(rbs_dir)
        signatures   = {}
        ivars        = {}
        attrs        = {}
        type_aliases = {}
        overloads    = {}

        return empty_result unless rbs_dir && Dir.exist?(rbs_dir)

        rbs_files = Dir.glob(File.join(rbs_dir, "**/*.rbs"))
        rbs_files.each do |file|
          parse_file(file, signatures, ivars, attrs, type_aliases, overloads)
        end

        log_stats(signatures, ivars, attrs, type_aliases) if @verbose

        Result.new(
          signatures:   signatures,
          ivars:        ivars,
          attrs:        attrs,
          type_aliases: type_aliases,
          overloads:    overloads
        )
      end

      private

      def empty_result
        Result.new(
          signatures:   {},
          ivars:        {},
          attrs:        {},
          type_aliases: {},
          overloads:    {}
        )
      end

      def log_stats(signatures, ivars, attrs, type_aliases)
        method_count = signatures.values.sum { |m| m.size }
        ivar_count   = ivars.values.sum { |i| i.size }
        attr_count   = attrs.values.sum { |a| a.size }
        type_count   = type_aliases.values.sum { |t| t.size }

        @logger&.info "Loaded from generated RBS: #{method_count} methods, " \
                      "#{ivar_count} ivars, #{attr_count} attrs, #{type_count} type aliases"
      end

      def parse_file(file, signatures, ivars, attrs, type_aliases, overloads)
        content = File.read(file)
        lines   = content.lines

        namespace_stack = []
        pending_comment = nil
        pending_method  = nil  # For collecting method overloads

        lines.each_with_index do |line, _idx|
          stripped = line.strip

          # Track module/class context
          if stripped =~ /^(?:class|module)\s+([\w:]+)/
            name            = Regexp.last_match(1)
            namespace_stack.push(name)
            pending_comment = nil
            next
          end

          # Track end statements
          if stripped == "end"
            namespace_stack.pop if namespace_stack.any?
            pending_comment = nil
            pending_method  = nil
            next
          end

          # Collect comments (may be description for next declaration)
          if stripped.start_with?("#")
            comment_text    = stripped.sub(/^#\s*/, "")
            pending_comment = pending_comment ? "#{pending_comment}\n#{comment_text}" : comment_text
            next
          end

          # Skip blank lines but preserve pending_comment
          next if stripped.empty?

          current_namespace = namespace_stack.join("::")
          next if current_namespace.empty?

          # Parse instance variable declarations: @name: Type
          if stripped =~ /^@(\w+):\s*(.+)$/
            ivar_name = Regexp.last_match(1)
            ivar_type = Regexp.last_match(2).strip

            ivars[current_namespace]          ||= {}
            ivars[current_namespace][ivar_name] = {
              type: ivar_type,
              desc: extract_first_line_desc(pending_comment)
            }
            pending_comment                     = nil
            next
          end

          # Parse attr_reader/attr_accessor: attr_reader name: Type
          if stripped =~ /^attr_(?:reader|accessor|writer)\s+(\w+):\s*(.+)$/
            attr_name = Regexp.last_match(1)
            attr_type = Regexp.last_match(2).strip

            attrs[current_namespace]          ||= {}
            attrs[current_namespace][attr_name] = {
              type: attr_type,
              desc: extract_first_line_desc(pending_comment)
            }
            pending_comment                     = nil
            next
          end

          # Parse type aliases: type name = definition
          if stripped =~ /^type\s+(\w+)\s*=\s*(.+)$/
            type_name = Regexp.last_match(1)
            type_def  = Regexp.last_match(2)

            type_aliases[current_namespace] ||= []
            type_aliases[current_namespace] << {
              name:        type_name,
              definition:  type_def,
              description: pending_comment
            }
            pending_comment                   = nil
            next
          end

          # Parse method signatures: def method_name: signature
          # Also handles: def self.method_name: signature
          if stripped =~ /^def\s+(?:self\.)?(\w+[?!=]?|\[\]=?):\s*(.+)$/
            method_name = Regexp.last_match(1)
            full_sig    = Regexp.last_match(2).strip

            signatures[current_namespace] ||= {}

            # Check if this is a continuation (overload) of previous method
            if pending_method == method_name
              overloads[current_namespace]              ||= {}
              overloads[current_namespace][method_name] ||= []
              overloads[current_namespace][method_name] << full_sig
            else
              # New method - parse signature and store
              signatures[current_namespace][method_name] = parse_signature(full_sig, pending_comment)
              pending_method                             = method_name
            end

            pending_comment = nil
            next
          end

          # Check for method overload continuation (line starting with |)
          if stripped.start_with?("|") && pending_method
            overload_sig = stripped.sub(/^\|\s*/, "").strip

            overloads[current_namespace]                 ||= {}
            overloads[current_namespace][pending_method] ||= []
            overloads[current_namespace][pending_method] << overload_sig
            next
          end

          # Any other non-blank line resets pending state
          pending_comment = nil
          pending_method  = nil
        end
      end

      def extract_first_line_desc(comment)
        return nil if comment.nil? || comment.empty?

        # Get first line, skip @rbs annotations
        lines = comment.lines.map(&:strip)
        lines.reject { |l| l.start_with?("@rbs") }.first
      end

      # Parse RBS signature into structured data.
      #
      # Handles formats like:
      #   () -> void
      #   (String name, ?Integer age) -> User
      #   [T] (T item) -> Array[T]
      #
      # @param sig [String] Full RBS signature
      # @param comment [String, nil] Preceding comment (may contain @rbs descriptions)
      # @return [Hash] Structured signature data
      def parse_signature(sig, comment = nil)
        result = {
          full:    sig,
          params:  {},
          returns: nil
        }

        # Extract descriptions from comment's @rbs annotations
        param_descs  = {}
        return_desc  = nil
        raises_type  = nil

        if comment
          comment.lines.each do |line|
            line = line.strip

            # @rbs param_name: Type -- description
            if line =~ /@rbs\s+(\w+):\s*\S+\s+--\s+(.+)$/
              param_descs[Regexp.last_match(1)] = capitalize_first(Regexp.last_match(2))
            end

            # @rbs return: Type -- description
            return_desc = capitalize_first(Regexp.last_match(1)) if line =~ /@rbs\s+return:\s*\S+\s+--\s+(.+)$/

            # @rbs raises: Type
            raises_type = Regexp.last_match(1).strip if line =~ /@rbs\s+raises:\s*(.+)$/
          end
        end

        # Parse the signature itself
        # Handle type parameters: [T] (...)
        sig_without_type_params = sig.sub(/^\[[^\]]+\]\s*/, "")

        if sig_without_type_params =~ /\A\(([^)]*)\)\s*->\s*(.+)\z/
          params_str       = Regexp.last_match(1)
          result[:returns] = { type: Regexp.last_match(2).strip, desc: return_desc }
          parse_params(params_str, result[:params], param_descs)
        elsif sig_without_type_params =~ /\A\(\)\s*->\s*(.+)\z/
          result[:returns] = { type: Regexp.last_match(1).strip, desc: return_desc }
        end

        result[:raises] = raises_type if raises_type
        result
      end

      def parse_params(params_str, result, descriptions)
        return if params_str.strip.empty?

        params = split_respecting_brackets(params_str)

        params.each do |param|
          param = param.strip
          next if param.empty?

          parse_single_param(param, result, descriptions)
        end
      end

      def parse_single_param(param, result, descriptions)
        # Keyword arg: `?name: Type` or `name: Type`
        if param =~ /\A\??(\w+):\s*(.+)\z/
          name         = Regexp.last_match(1)
          type         = Regexp.last_match(2).strip
          result[name] = { type: type, desc: descriptions[name] }
        # Block param: `?{ (Type) -> Type }` or `^(Type) -> Type`
        elsif param =~ /\A\??[{^]/
          # Store as special block param
          result["&block"] = { type: param, desc: descriptions["block"] }
        # Positional: `?Type name` or `Type name`
        elsif param =~ /\A\??(.+?)\s+(\w+)\z/
          type         = Regexp.last_match(1).strip
          name         = Regexp.last_match(2)
          result[name] = { type: type, desc: descriptions[name] }
        end
      end

      def capitalize_first(str)
        return nil if str.nil? || str.strip.empty?

        s = str.strip
        s[0].upcase + s[1..]
      end

      # Split string by commas while respecting nested brackets [], {}, ().
      def split_respecting_brackets(str)
        result  = []
        current = +""
        depth   = 0

        str.each_char do |c|
          case c
          when "[", "{", "("
            depth += 1
            current << c
          when "]", "}", ")"
            depth -= 1
            current << c
          when ","
            if depth.zero?
              result << current
              current = +""
            else
              current << c
            end
          else
            current << c
          end
        end

        result << current unless current.empty?
        result
      end
    end
  end
end
