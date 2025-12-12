# frozen_string_literal: true

require_relative "document_model"

module Chiridion
  class Engine
    # Comprehensive semantic extraction from YARD registry.
    #
    # Unlike the simpler Extractor, this captures ALL available metadata from
    # YARD and RBS, populating the DocumentModel structures completely. It
    # addresses the "data being discarded" issues documented in TODO.md.
    #
    # Key improvements over Extractor:
    # - @option tags for hash parameter documentation
    # - @yield, @yieldparam, @yieldreturn for block documentation
    # - @api, @deprecated, @abstract, @note tags
    # - @raise exceptions
    # - Instance variable types (@rbs @name: Type)
    # - Method overloads from RBS
    #
    # Design: Extract everything, render selectively.
    class SemanticExtractor
      include DocumentModel

      def initialize(
        rbs_types:,
        rbs_attr_types: {},
        rbs_ivar_types: {},
        type_aliases: {},
        spec_examples: {},
        namespace_filter: nil,
        logger: nil
      )
        @rbs_types        = rbs_types || {}
        @rbs_attr_types   = rbs_attr_types || {}
        @rbs_ivar_types   = rbs_ivar_types || {}
        @type_aliases     = type_aliases || {}
        @spec_examples    = spec_examples || {}
        @namespace_filter = namespace_filter
        @logger           = logger
        @type_merger      = TypeMerger.new(logger)
      end

      # Extract complete documentation from YARD registry.
      #
      # @param registry [YARD::Registry] Parsed YARD registry
      # @param title [String] Project title
      # @param description [String] Project description
      # @param root [String] Project root for relative path calculation
      # @return [ProjectDoc] Complete documentation structure
      def extract(registry, title: "API Documentation", description: nil, root: Dir.pwd)
        namespaces = registry.all(:class, :module)
                             .select { |obj| should_document?(obj) }
                             .map { |obj| extract_namespace(obj) }

        files = group_by_file(namespaces, root)

        ProjectDoc.new(
          title:        title,
          description:  description,
          namespaces:   namespaces,
          files:        files,
          type_aliases: @type_aliases.transform_values { |types| types.map { |t| to_type_alias_doc(t) } },
          generated_at: Time.now.utc
        )
      end

      private

      # Group namespaces by their source file.
      #
      # Creates FileDoc entries for each unique source file, collecting all
      # namespaces defined in that file. Also associates type aliases with
      # their defining files.
      #
      # @param namespaces [Array<NamespaceDoc>] All extracted namespaces
      # @param root [String] Project root for relative path calculation
      # @return [Array<FileDoc>] Namespaces grouped by source file
      def group_by_file(namespaces, root)
        # Group namespaces by their source file
        by_file = Hash.new { |h, k| h[k] = [] }

        namespaces.each do |ns|
          next unless ns.file

          relative_path = make_relative(ns.file, root)
          by_file[relative_path] << ns
        end

        # Create FileDoc for each file
        by_file.map do |path, file_namespaces|
          # Collect type aliases from these namespaces
          file_aliases = file_namespaces.flat_map(&:type_aliases)

          # Try to get line count
          absolute_path = File.join(root, path)
          line_count    = File.exist?(absolute_path) ? File.read(absolute_path).lines.count : nil

          FileDoc.new(
            path:         path,
            namespaces:   file_namespaces.sort_by(&:path),
            type_aliases: file_aliases,
            line_count:   line_count
          )
        end.sort_by(&:path)
      end

      def make_relative(absolute_path, root)
        return absolute_path unless absolute_path&.start_with?(root)

        absolute_path.delete_prefix("#{root}/")
      end

      def should_document?(obj)
        return true unless @namespace_filter

        obj.path.start_with?(@namespace_filter)
      end

      # Extract complete namespace (class/module) documentation.
      def extract_namespace(obj)
        path     = obj.path
        is_class = obj.is_a?(YARD::CodeObjects::ClassObject)

        NamespaceDoc.new(
          name:             obj.name.to_s,
          path:             path,
          type:             is_class ? :class : :module,
          superclass:       is_class ? obj.superclass&.path : nil,
          docstring:        clean_docstring(obj.docstring.to_s),
          examples:         extract_examples(obj),
          notes:            extract_notes(obj),
          see_also:         extract_see_tags(obj),
          api:              obj.tag(:api)&.text,
          deprecated:       extract_deprecated(obj),
          abstract:         obj.has_tag?(:abstract),
          since:            obj.tag(:since)&.text,
          todo:             obj.tag(:todo)&.text,
          includes:         obj.instance_mixins.map(&:path),
          extends:          obj.class_mixins.map(&:path),
          constants:        extract_constants(obj),
          type_aliases:     extract_local_type_aliases(path),
          ivars:            extract_ivars(path),
          attributes:       extract_attributes(obj, path),
          methods:          extract_methods(obj, path, :public),
          private_methods:  extract_methods(obj, path, :private),
          file:             obj.file,
          line:             obj.line,
          end_line:         compute_end_line(obj),
          rbs_file:         find_rbs_file(path),
          spec_examples:    @spec_examples[path],
          referenced_types: [] # Populated post-extraction
        )
      end

      def extract_examples(obj)
        obj.tags(:example).map do |t|
          ExampleDoc.new(name: t.name, code: t.text)
        end
      end

      def extract_notes(obj) = obj.tags(:note).map(&:text)

      def extract_see_tags(obj) = obj.tags(:see).map do |t|
        SeeDoc.new(target: t.name, text: t.text)
      end

      def extract_deprecated(obj)
        tag = obj.tag(:deprecated)
        return nil unless tag

        tag.text.to_s.empty? ? "" : tag.text
      end

      def extract_constants(obj)
        obj.constants.map do |c|
          ConstantDoc.new(
            name:        c.name.to_s,
            value:       c.value.to_s,
            type:        nil, # TODO: extract from RBS if available
            description: clean_docstring(c.docstring.to_s)
          )
        end
      end

      def extract_local_type_aliases(class_path)
        (@type_aliases[class_path] || []).map { |t| to_type_alias_doc(t, class_path) }
      end

      def to_type_alias_doc(t, namespace = nil)
        TypeAliasDoc.new(
          name:        t[:name],
          definition:  t[:definition],
          description: t[:description],
          namespace:   namespace || t[:namespace] || ""
        )
      end

      def extract_ivars(class_path)
        ivar_data = @rbs_ivar_types[class_path] || {}
        ivar_data.map do |name, info|
          IvarDoc.new(
            name:        name.to_s,
            type:        info.is_a?(Hash) ? info[:type] : info,
            description: info.is_a?(Hash) ? info[:desc] : nil
          )
        end
      end

      def extract_attributes(obj, class_path)
        # Find attr_reader/attr_writer/attr_accessor methods
        readers = {}
        writers = {}

        obj.meths(scope: :instance, visibility: :public).each do |m|
          source_info = extract_source(m)
          next unless source_info[:attr_type]

          if source_info[:attr_type] == :reader
            readers[m.name.to_s] = extract_method(m, class_path, :instance)
          elsif source_info[:attr_type] == :writer
            name          = m.name.to_s.chomp("=")
            writers[name] = extract_method(m, class_path, :instance)
          end
        end

        # Synthesize AttributeDoc for each attribute
        all_names = (readers.keys + writers.keys).uniq.sort
        all_names.map do |name|
          reader = readers[name]
          writer = writers[name]

          mode = case [reader.nil?, writer.nil?]
                 when [false, false] then :read_write
                 when [false, true]  then :read
                 else :write
                 end

          # Get type from RBS attr annotations first, then from YARD
          type = resolve_attr_type(name, class_path, reader, writer)
          desc = resolve_attr_description(name, class_path, reader, writer)

          AttributeDoc.new(
            name:        name,
            type:        type,
            description: desc,
            mode:        mode,
            reader:      reader,
            writer:      writer
          )
        end
      end

      def resolve_attr_type(name, class_path, reader, writer)
        # Check RBS attr_types first
        rbs_data = @rbs_attr_types.dig(class_path, name)
        if rbs_data
          type = rbs_data.is_a?(Hash) ? rbs_data[:type] : rbs_data
          return type if type && type != "untyped"
        end

        # Fall back to YARD types
        reader&.returns&.type || writer&.params&.first&.type
      end

      def resolve_attr_description(name, class_path, reader, writer)
        # Check RBS attr_types first
        rbs_data = @rbs_attr_types.dig(class_path, name)
        return rbs_data[:desc] if rbs_data.is_a?(Hash) && rbs_data[:desc] && !rbs_data[:desc].empty?

        # Fall back to YARD descriptions
        reader&.returns&.description || writer&.params&.first&.description
      end

      def extract_methods(obj, class_path, visibility)
        scope_methods = []

        [:instance, :class].each do |scope|
          obj.meths(scope: scope, visibility: visibility).each do |m|
            method_doc = extract_method(m, class_path, scope)
            # Skip pure attr methods (already in attributes)
            next if method_doc.attr_type

            scope_methods << method_doc
          end
        end

        scope_methods
      end

      def extract_method(meth, class_path, scope)
        rbs_data    = @rbs_types.dig(class_path, meth.name.to_s)
        source_info = extract_source(meth)

        # Extract and merge params
        yard_params   = extract_yard_params(meth)
        merged_params = merge_params(yard_params, rbs_data)

        # Extract options for hash params, merging with RBS record types
        options = extract_options(meth, rbs_data)

        # Extract return
        returns = extract_return(meth, rbs_data)

        # Extract yield/block info
        yields = extract_yields(meth, rbs_data)

        # Extract raises
        raises = extract_raises(meth, rbs_data)

        MethodDoc.new(
          name:              meth.name,
          scope:             scope,
          visibility:        meth.visibility,
          signature:         meth.signature,
          docstring:         clean_docstring(meth.docstring.to_s),
          params:            merged_params,
          options:           options,
          returns:           returns,
          yields:            yields,
          raises:            raises,
          examples:          extract_examples(meth),
          notes:             extract_notes(meth),
          see_also:          extract_see_tags(meth),
          api:               meth.tag(:api)&.text,
          deprecated:        extract_deprecated(meth),
          abstract:          meth.has_tag?(:abstract),
          since:             meth.tag(:since)&.text,
          todo:              meth.tag(:todo)&.text,
          rbs_signature:     rbs_data&.dig(:full),
          overloads:         extract_overloads(rbs_data),
          source:            source_info[:source],
          source_body_lines: source_info[:body_lines],
          attr_type:         source_info[:attr_type],
          file:              meth.file,
          line:              meth.line,
          spec_examples:     method_spec_examples(class_path, meth.name),
          spec_behaviors:    method_spec_behaviors(class_path, meth.name)
        )
      end

      def extract_yard_params(meth)
        param_tags = meth.tags(:param).to_h { |t| [t.name, { types: t.types, text: t.text }] }

        meth.parameters.map do |name, default|
          clean_name = name.to_s.gsub(/\A[*&]+/, "").delete_suffix(":")
          tag_info   = param_tags[clean_name] || {}

          ParamDoc.new(
            name:        clean_name,
            type:        tag_info[:types]&.first,
            description: tag_info[:text],
            default:     default,
            prefix:      ParamDoc.extract_prefix(name)
          )
        end
      end

      def merge_params(yard_params, rbs_data)
        return yard_params unless rbs_data&.dig(:params)

        rbs_params = rbs_data[:params]
        yard_params.map do |param|
          rbs_info = rbs_params[param.name]
          next param unless rbs_info

          rbs_type = rbs_info.is_a?(Hash) ? rbs_info[:type] : rbs_info
          rbs_desc = rbs_info.is_a?(Hash) ? rbs_info[:desc] : nil

          ParamDoc.new(
            name:        param.name,
            type:        rbs_type || param.type,
            description: merge_descriptions(param.description, rbs_desc),
            default:     param.default,
            prefix:      param.prefix
          )
        end
      end

      # Extract @option tags for hash parameters, merging with RBS record types.
      #
      # RBS provides types via record syntax: `{ key: Type, key2: Type2 }`
      # YARD @option provides semantic descriptions for each key.
      # Chiridion merges by key name (RBS type wins).
      #
      # @param meth [YARD::CodeObjects::MethodObject]
      # @param rbs_data [Hash, nil] RBS type data for this method
      # @return [Array<OptionDoc>]
      def extract_options(meth, rbs_data = nil)
        yard_options = meth.tags(:option)

        # Build map of RBS record types by param name
        rbs_record_types = extract_rbs_record_types(rbs_data)

        yard_options.map do |opt|
          param_name = opt.name.to_s

          # @option tags have a nested DefaultTag in `pair` containing the key info
          pair = opt.pair
          key_name    = pair&.name&.to_s&.delete_prefix(":") || "unknown"
          yard_type   = pair&.types&.first
          description = pair&.text

          # Look up RBS type for this key (RBS wins over YARD)
          rbs_type = rbs_record_types.dig(param_name, key_name)

          OptionDoc.new(
            param_name:  param_name,
            key:         key_name,
            type:        rbs_type || yard_type,
            description: description
          )
        end
      end

      # Extract RBS record types from method params.
      #
      # For a param like `options: { file: String?, path: String? }`,
      # returns { "options" => { "file" => "String?", "path" => "String?" } }
      #
      # @param rbs_data [Hash, nil]
      # @return [Hash{String => Hash{String => String}}]
      def extract_rbs_record_types(rbs_data)
        return {} unless rbs_data&.dig(:params)

        result = {}
        rbs_data[:params].each do |param_name, param_info|
          type_str = param_info.is_a?(Hash) ? param_info[:type] : param_info
          next unless type_str

          # Check if it's a record type { key: Type, ... }
          parsed                  = parse_rbs_record_type(type_str)
          result[param_name.to_s] = parsed if parsed.any?
        end
        result
      end

      # Parse an RBS record type like "{ file: String?, path: String? }"
      #
      # @param type_str [String]
      # @return [Hash{String => String}] key name to type mapping
      def parse_rbs_record_type(type_str)
        return {} unless type_str

        clean = type_str.strip
        return {} unless clean.start_with?("{") && clean.end_with?("}")

        # Remove outer braces
        inner = clean[1..-2].strip
        return {} if inner.empty?

        result = {}
        # Split on commas, respecting nested brackets/braces
        pairs  = split_record_pairs(inner)

        pairs.each do |pair|
          # Match "key: Type" or "key?: Type"
          next unless (match = pair.match(/\A(\w+)\??\s*:\s*(.+)\z/))

          key                = match[1]
          type               = match[2].strip
          result[key]        = type
        end

        result
      end

      # Split record type pairs, respecting nested structures.
      #
      # "file: String, data: Hash[Symbol, String]" → ["file: String", "data: Hash[Symbol, String]"]
      def split_record_pairs(str)
        return [] if str.nil? || str.strip.empty?

        pairs   = []
        current = +""
        depth   = 0

        str.each_char do |c|
          case c
          when "[", "(", "{" then depth += 1
                                  current << c
          when "]", ")", "}" then depth -= 1
                                  current << c
          when ","
            if depth.zero?
              pairs << current.strip unless current.strip.empty?
              current = +""
            else
              current << c
            end
          else
            current << c
          end
        end

        pairs << current.strip unless current.strip.empty?
        pairs
      end

      def extract_return(meth, rbs_data)
        yard_tag  = meth.tag(:return)
        yard_type = yard_tag&.types&.first

        if rbs_data&.dig(:returns)
          rbs_ret  = rbs_data[:returns]
          rbs_type = rbs_ret.is_a?(Hash) ? rbs_ret[:type] : rbs_ret
          rbs_desc = rbs_ret.is_a?(Hash) ? rbs_ret[:desc] : nil

          # If RBS says void but YARD has a type (e.g., auto-generated for initialize),
          # prefer YARD's type. This handles `# @rbs () -> void` on initialize methods.
          final_type = (rbs_type == "void" && yard_type) ? yard_type : rbs_type

          ReturnDoc.new(
            type:        final_type,
            description: merge_descriptions(yard_tag&.text, rbs_desc)
          )
        elsif yard_tag
          ReturnDoc.new(
            type:        yard_type,
            description: yard_tag.text
          )
        end
      end

      # Extract @yield, @yieldparam, @yieldreturn, and RBS block signatures.
      #
      # Merges RBS block type `(User, Integer) -> bool` with YARD @yieldparam
      # names/descriptions by position. RBS provides authoritative types,
      # YARD provides semantic names and descriptions.
      def extract_yields(meth, rbs_data)
        yield_tag   = meth.tag(:yield)
        yieldparams = meth.tags(:yieldparam)
        yieldreturn = meth.tag(:yieldreturn)

        # Extract RBS block info
        block_type        = nil
        block_desc        = nil
        block_param_types = []
        block_return_type = nil

        if rbs_data&.dig(:params)
          block_param = rbs_data[:params].find { |k, _| k.start_with?("&") || k == "block" }
          if block_param
            block_info = block_param[1]
            block_type = block_info.is_a?(Hash) ? block_info[:type] : block_info
            block_desc = block_info.is_a?(Hash) ? block_info[:desc] : nil

            # Parse block type to extract positional param types and return type
            if block_type
              parsed            = parse_block_type(block_type)
              block_param_types = parsed[:param_types]
              block_return_type = parsed[:return_type]
            end
          end
        end

        return nil if yield_tag.nil? && yieldparams.empty? && yieldreturn.nil? && block_type.nil?

        # Merge yieldparams with RBS block param types by position
        merged_params = yieldparams.each_with_index.map do |t, i|
          rbs_type = block_param_types[i]
          ParamDoc.new(
            name:        t.name,
            type:        rbs_type || t.types&.first, # RBS type takes precedence
            description: t.text,
            default:     nil,
            prefix:      nil
          )
        end

        YieldDoc.new(
          description: yield_tag&.text || block_desc,
          params:      merged_params,
          return_type: block_return_type || yieldreturn&.types&.first,
          return_desc: yieldreturn&.text,
          block_type:  block_type
        )
      end

      # Parse an RBS block type like "(User, Integer) -> bool"
      #
      # @return [Hash] { param_types: ["User", "Integer"], return_type: "bool" }
      def parse_block_type(block_type)
        return { param_types: [], return_type: nil } unless block_type

        # Handle formats: (T1, T2) -> R, { (T1, T2) -> R }, ^(T1, T2) -> R
        clean = block_type.strip.delete_prefix("{").delete_suffix("}").delete_prefix("^").strip

        if (match = clean.match(/\A\(([^)]*)\)\s*->\s*(.+)\z/))
          params_str  = match[1]
          return_type = match[2].strip

          { param_types: split_type_params(params_str), return_type: return_type }
        else
          { param_types: [], return_type: nil }
        end
      end

      # Split comma-separated type params, respecting nested brackets.
      #
      # "User, Array[String], Hash[Symbol, Integer]" → ["User", "Array[String]", "Hash[Symbol, Integer]"]
      def split_type_params(str)
        return [] if str.nil? || str.strip.empty?

        params  = []
        current = +""
        depth   = 0

        str.each_char do |c|
          case c
          when "[", "(" then depth += 1
                             current << c
          when "]", ")" then depth -= 1
                             current << c
          when ","
            if depth.zero?
              params << current.strip unless current.strip.empty?
              current = +""
            else
              current << c
            end
          else
            current << c
          end
        end

        params << current.strip unless current.strip.empty?
        params
      end

      # Extract @raise tags and @rbs raises.
      def extract_raises(meth, rbs_data)
        yard_raises = meth.tags(:raise).map do |t|
          RaiseDoc.new(type: t.types&.first || t.name, description: t.text)
        end

        # Add RBS raises if present
        if rbs_data&.dig(:raises)
          rbs_raise = rbs_data[:raises]
          yard_raises << RaiseDoc.new(type: rbs_raise, description: nil) unless yard_raises.any? do |r|
            r.type == rbs_raise
          end
        end

        yard_raises
      end

      def extract_overloads(rbs_data)
        return [] unless rbs_data&.dig(:overloads)

        rbs_data[:overloads].map do |sig|
          OverloadDoc.new(signature: sig, description: nil)
        end
      end

      def merge_descriptions(yard_desc, rbs_desc)
        return rbs_desc if yard_desc.to_s.strip.empty?
        return yard_desc if rbs_desc.to_s.strip.empty?

        # Longer description wins; tie goes to RBS (co-located)
        rbs_desc.to_s.length >= yard_desc.to_s.length ? rbs_desc : yard_desc
      end

      def clean_docstring(str)
        return "" if str.nil? || str.empty?

        # Strip @rbs! blocks (multi-line RBS annotations meant for RBS::Inline)
        # The block continues while lines are indented (start with whitespace)
        cleaned = str.gsub(/@rbs!\s*\n(?:\s+.*(?:\n|\z))*/, "")

        cleaned.lines
               .reject { |line| line.strip.match?(/^rubocop:(disable|enable|todo)\b/i) }
               .join
               .strip
      end

      def compute_end_line(obj)
        return nil unless obj.source

        obj.line + obj.source.lines.count - 1
      end

      def extract_source(meth)
        source = meth.source
        return { source: nil, body_lines: nil, attr_type: nil } unless source

        condensed = condense_attr_source(source)
        return { source: condensed[:source], body_lines: 0, attr_type: condensed[:attr_type] } if condensed

        lines = source.lines
        total = lines.size

        if total == 1 || source.match?(/\Adef\s+\S+.*=/)
          { source: source, body_lines: 0, attr_type: nil }
        else
          { source: source, body_lines: [total - 2, 0].max, attr_type: nil }
        end
      end

      def condense_attr_source(source)
        lines = source.lines.map(&:strip)
        return nil unless lines.size == 3 && lines.last == "end"

        if (reader_match = lines[0].match(/\Adef\s+(\w+)\z/)) && (ivar_match = lines[1].match(/\A@(\w+)\z/))
          return { source: "def #{reader_match[1]} = @#{ivar_match[1]}", attr_type: :reader }
        end

        if (writer_match = lines[0].match(/\Adef\s+(\w+)=\((\w+)\)\z/)) && lines[1].match(/\A@(\w+)\s*=\s*(\w+)\z/)
          return { source:    "def #{writer_match[1]}=(#{writer_match[2]}) = (@#{writer_match[1]} = #{writer_match[2]})",
                   attr_type: :writer }
        end

        nil
      end

      def find_rbs_file(class_path)
        parts = class_path.split("::").map { |part| to_snake_case(part) }
        path  = "sig/#{parts.join('/')}.rbs"
        File.exist?(path) ? path : nil
      end

      def to_snake_case(str)
        str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
           .gsub(/([a-z\d])([A-Z])/, '\1_\2')
           .downcase
      end

      def method_spec_examples(class_path, method_name) = lookup_spec_data(class_path, :method_examples, method_name)

      def method_spec_behaviors(class_path, method_name) = lookup_spec_data(class_path, :behaviors, method_name)

      def lookup_spec_data(class_path, category, method_name)
        return [] unless @spec_examples[class_path]

        @spec_examples[class_path][category][".#{method_name}"] ||
          @spec_examples[class_path][category]["##{method_name}"] || []
      end
    end
  end
end
