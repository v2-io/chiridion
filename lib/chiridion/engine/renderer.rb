# frozen_string_literal: true

module Chiridion
  class Engine
    # Renders documentation to Obsidian-compatible markdown.
    #
    # Uses Liquid templates for the document body content, while YAML frontmatter
    # is rendered directly in Ruby due to its complex formatting requirements
    # (flow vs block arrays, proper quoting, etc.).
    #
    # ## Template Customization
    #
    # Templates are loaded from the gem's templates/ directory by default.
    # Override by passing a custom templates_path to the constructor.
    #
    # ## Enhanced Frontmatter
    #
    # All generated documents include enhanced YAML frontmatter for Obsidian:
    # - **Navigation**: parent links for breadcrumb traversal
    # - **Discovery**: tags for filtering, related links for exploration
    # - **Search**: aliases for finding by short name, description for preview
    class Renderer
      def initialize(
        namespace_strip:,
        include_specs:,
        root: Dir.pwd,
        github_repo: nil,
        github_branch: "main",
        project_title: "API Documentation",
        index_description: nil,
        templates_path: nil,
        inline_source_threshold: 10,
        rbs_attr_types: {}
      )
        @namespace_strip         = namespace_strip
        @include_specs           = include_specs
        @root                    = root
        @index_description       = index_description || "Auto-generated from source code."
        @inline_source_threshold = inline_source_threshold
        @rbs_attr_types          = rbs_attr_types || {}
        @class_linker            = ClassLinker.new(namespace_strip: namespace_strip)
        @github_linker           = GithubLinker.new(repo: github_repo, branch: github_branch, root: root)
        @frontmatter_builder     = FrontmatterBuilder.new(
          @class_linker,
          namespace_strip: namespace_strip,
          project_title:   project_title
        )
        @template_renderer       = TemplateRenderer.new(templates_path: templates_path)
      end

      # Register known classes for cross-reference linking and inheritance.
      #
      # @param structure [Hash] Documentation structure from Extractor
      def register_classes(structure)
        @class_linker.register_classes(structure)
        @frontmatter_builder.register_inheritance(structure)
      end

      # Render the documentation index.
      #
      # @param structure [Hash] Documentation structure from Extractor
      # @return [String] Markdown index
      def render_index(structure)
        frontmatter = @frontmatter_builder.build_index

        classes = structure[:classes].map do |c|
          { path: c[:path], link_path: link(c[:path]) }
        end

        modules = structure[:modules].map do |m|
          { path: m[:path], link_path: link(m[:path]) }
        end

        body = @template_renderer.render_index(
          title:       frontmatter[:title],
          description: @index_description,
          classes:     classes,
          modules:     modules
        )

        "#{render_frontmatter(frontmatter)}\n\n#{body}\n"
      end

      # Render class documentation.
      #
      # @param klass [Hash] Class data from Extractor
      # @return [String] Markdown documentation
      def render_class(klass) = render_document(klass, include_mixins: true)

      # Render module documentation.
      #
      # @param mod [Hash] Module data from Extractor
      # @return [String] Markdown documentation
      def render_module(mod) = render_document(mod, include_mixins: false)

      # Render type aliases reference page.
      #
      # @param type_aliases [Hash{String => Array<Hash>}] namespace -> types mapping
      # @return [String] Markdown documentation
      def render_type_aliases(type_aliases)
        return nil if type_aliases.nil? || type_aliases.empty?

        frontmatter = {
          generated:   Time.now.utc.iso8601,
          title:       "Type Aliases Reference",
          type:        "reference",
          description: "RBS type aliases defined across the codebase",
          tags:        %w[types rbs reference]
        }

        # Convert to array format for template
        namespaces = type_aliases.map do |namespace, types|
          {
            name:  namespace.empty? ? "(root)" : namespace,
            types: types.map do |t|
              {
                name:        t[:name],
                definition:  t[:definition],
                description: t[:description]
              }
            end
          }
        end.sort_by { |ns| ns[:name] }

        body = @template_renderer.render_type_aliases(
          title:       "Type Aliases Reference",
          description: "RBS type aliases defined across the codebase. " \
                       "These types can be referenced in `@rbs` annotations.",
          namespaces:  namespaces
        )

        "#{render_frontmatter(frontmatter)}\n\n#{body}\n"
      end

      private

      def render_document(obj, include_mixins:)
        frontmatter = build_document_frontmatter(obj)
        docstring   = @class_linker.linkify_docstring(obj[:docstring], context: obj[:path])

        # Partition attributes from regular methods
        attrs, regular  = partition_attributes(obj[:methods] || [])
        attrs_section   = render_attributes_section(attrs, obj[:path])
        methods_section = render_methods_only(regular, obj[:path])
        private_summary = render_private_methods_summary(obj[:private_methods])
        full_methods    = [methods_section, private_summary].reject(&:empty?).join("\n\n")

        body = @template_renderer.render_document(
          title:              obj[:path],
          docstring:          docstring,
          mixins:             include_mixins ? render_mixins(obj) : nil,
          examples:           obj[:examples] || [],
          spec_examples:      render_spec_examples(obj),
          see_also:           render_see_also(obj[:see_also], obj[:path]),
          constants_section:  render_constants(obj[:constants]),
          types_section:      render_types_section(obj[:referenced_types]),
          attributes_section: attrs_section,
          methods_section:    full_methods
        )

        "#{render_frontmatter(frontmatter)}\n\n#{body}\n"
      end

      def build_document_frontmatter(obj)
        frontmatter              = @frontmatter_builder.build(obj)
        # Convert absolute paths to relative
        frontmatter[:source]     = relative_path(frontmatter[:source])
        frontmatter[:source]     = format_source_with_lines(frontmatter[:source], obj[:line], obj[:end_line])
        frontmatter[:source_url] = @github_linker.url(
          frontmatter[:source].split(":").first,
          obj[:line],
          obj[:end_line]
        )
        frontmatter
      end

      # Render frontmatter hash to YAML.
      #
      # Uses flow style [a, b, c] for compact arrays (methods, constants, tags).
      # Uses block style for arrays with wikilinks (related, inherited_by).
      # Omits nil values.
      def render_frontmatter(frontmatter)
        block_style_fields = [:related, :inherited_by]

        lines = ["---"]
        frontmatter.each do |key, value|
          next if value.nil?

          if value.is_a?(Array)
            if block_style_fields.include?(key)
              lines << "#{key}:"
              value.each { |v| lines << "  - #{v}" }
            else
              lines << "#{key}: [#{value.join(', ')}]"
            end
          else
            lines << "#{key}: #{value}"
          end
        end
        lines << "---"
        lines.join("\n")
      end

      def relative_path(absolute_path)
        return absolute_path unless absolute_path&.start_with?(@root)

        absolute_path.delete_prefix("#{@root}/")
      end

      def link(class_path)
        stripped    = @namespace_strip ? class_path.sub(/^#{Regexp.escape(@namespace_strip)}/, "") : class_path
        parts       = stripped.split("::")
        kebab_parts = parts.map { |p| to_kebab_case(p) }
        File.join(*kebab_parts[0..-2], kebab_parts.last)
      end

      def render_mixins(klass)
        return nil unless klass[:includes].any? || klass[:extends].any?

        parts = []
        if klass[:includes].any?
          linked = klass[:includes].map { |m| @class_linker.link(m, context: klass[:path]) }
          parts << "**Includes:** #{linked.join(', ')}"
        end
        if klass[:extends].any?
          linked = klass[:extends].map { |m| @class_linker.link(m, context: klass[:path]) }
          parts << "**Extended by:** #{linked.join(', ')}"
        end
        parts.join(" · ")
      end

      def render_see_also(see_tags, context)
        return nil if see_tags.nil? || see_tags.empty?

        links = see_tags.map do |tag|
          link_text = @class_linker.link(tag[:name], context: context)
          tag[:text].to_s.empty? ? link_text : "#{link_text} — #{tag[:text]}"
        end
        "**See also:** #{links.join(' · ')}"
      end

      def render_spec_examples(obj)
        return nil unless @include_specs && obj[:spec_examples]

        ex = obj[:spec_examples]
        return nil if ex[:lets].empty? && ex[:subjects].empty?

        parts = ["## Usage Examples (from specs)"]
        ex[:subjects].each { |e| parts << "**#{e[:name]}:**\n\n```ruby\n#{clean(e[:code], obj[:path])}\n```" }
        ex[:lets].first(5).each { |e| parts << "**#{e[:name]}:**\n\n```ruby\n#{clean(e[:code], obj[:path])}\n```" }
        parts.join("\n\n")
      end

      def clean(code, class_path) = code.gsub("described_class", class_path.split("::").last).strip

      def format_source_with_lines(path, start_line, end_line)
        return path unless start_line

        if end_line && end_line != start_line
          "#{path}:#{start_line}–#{end_line}"
        else
          "#{path}:#{start_line}"
        end
      end

      def render_constants(constants)
        return "" if constants.nil? || constants.empty?

        _, complex = partition_constants(constants)

        constant_data = constants.map do |c|
          {
            name:       c[:name],
            value:      format_constant_value(c[:value], complex.include?(c)),
            docstring:  c[:docstring].to_s,
            is_complex: complex.include?(c)
          }
        end

        complex_data = complex.map do |c|
          {
            name:      c[:name],
            value:     strip_freeze(c[:value]),
            docstring: c[:docstring].to_s
          }
        end

        @template_renderer.render_constants(
          constants:         constant_data,
          complex_constants: complex_data
        )
      end

      def render_types_section(referenced_types)
        return "" if referenced_types.nil? || referenced_types.empty?

        types_data = referenced_types.map do |t|
          {
            name:        t[:name],
            definition:  t[:definition],
            description: t[:description],
            namespace:   t[:namespace]
          }
        end

        @template_renderer.render_types(types: types_data)
      end

      def partition_constants(constants) = constants.partition { |c| !complex_constant?(c) }

      def complex_constant?(c)
        value = c[:value].to_s
        doc   = c[:docstring].to_s

        # Complex if value has multiple lines
        return true if value.count("\n") > 1

        # Complex if docstring has markdown structure or is lengthy
        return true if doc.count("\n") > 1
        return true if doc.match?(/^#+\s/)           # Headers
        return true if doc.match?(/^[-*]\s/)         # Bullet points
        return true if doc.length > 120              # Long single-line descriptions

        false
      end

      def format_constant_value(value, is_complex)
        return "" if is_complex
        return "nil" if value.nil?

        strip_freeze(value.to_s).gsub("|", "\\|").gsub("\n", "<br />")
      end

      def strip_freeze(str) = str.to_s.delete_suffix(".freeze")

      def render_methods_only(methods, context)
        return "" if methods.nil? || methods.empty?

        rendered_methods = methods.map { |m| render_method(m, context) }
        @template_renderer.render_methods(methods: rendered_methods)
      end

      # Partition methods into attributes (reader/writer pairs) and regular methods.
      # Returns [attrs_hash, regular_methods] where attrs_hash maps name -> {reader:, writer:}
      def partition_attributes(methods)
        attrs   = {}
        regular = []

        methods.each do |m|
          case m[:attr_type]
          when :reader
            name           = m[:name].to_s
            (attrs[name] ||= {})[:reader] = m
          when :writer
            name           = m[:name].to_s.chomp("=")
            (attrs[name] ||= {})[:writer] = m
          else
            regular << m
          end
        end

        [attrs, regular]
      end

      # Render attributes section with param-like formatting.
      def render_attributes_section(attrs, class_path)
        return "" if attrs.empty?

        sorted       = attrs.sort_by { |name, _| name }
        max_name_len = sorted.map { |name, _| name.length }.max

        # Build inners to find max width
        inners        = sorted.map { |name, info| build_attr_inner(name, info, max_name_len, class_path) }
        max_inner_len = inners.map(&:length).max

        lines = sorted.zip(inners).map do |(name, info), inner|
          format_attr_line(name, info, inner, max_inner_len, class_path)
        end

        "## Attributes\n\n#{lines.join("\n")}"
      end

      def build_attr_inner(name, info, max_name_len, class_path)
        type   = attr_type_str(info, name, class_path)
        padded = name.ljust(max_name_len)
        type ? "#{padded} : #{type}" : padded
      end

      def format_attr_line(name, info, inner, max_inner_len, class_path)
        mode       = attr_mode(info)
        desc       = attr_description(name, info, class_path)
        padded_sig = "⟨#{inner}⟩".ljust(max_inner_len + 2)

        # Prepend (Read) or (Write) for non-rw attributes
        prefix = case mode
                 when "r" then "(Read) "
                 when "w" then "(Write) "
                 else ""
                 end

        full_desc = "#{prefix}#{desc}".strip
        full_desc.empty? ? "`#{padded_sig}`" : "`#{padded_sig}` — #{full_desc}"
      end

      def attr_mode(info)
        has_reader = info[:reader]
        has_writer = info[:writer]
        return "rw" if has_reader && has_writer
        return "r" if has_reader

        "w"
      end

      def attr_description(name, info, class_path)
        # First check @rbs_attr_types for description (most specific)
        rbs_data = @rbs_attr_types.dig(class_path, name)
        rbs_desc = rbs_data[:desc] if rbs_data.is_a?(Hash)
        return rbs_desc if rbs_desc && !rbs_desc.empty?

        # Fall back to YARD reader's return description, then writer's
        reader_desc = info[:reader]&.dig(:returns, :text).to_s
        desc        = reader_desc.empty? ? info[:writer]&.dig(:returns, :text).to_s : reader_desc
        # Collapse to single line, capitalize
        clean       = desc.gsub(/\s*\n\s*/, " ").strip
        capitalize_first(clean)
      end

      def attr_type_str(info, attr_name, class_path)
        # First check @rbs_attr_types (from #: annotations or @rbs! blocks)
        rbs_data = @rbs_attr_types.dig(class_path, attr_name)
        rbs_type = rbs_data.is_a?(Hash) ? rbs_data[:type] : rbs_data
        return rbs_type if rbs_type && rbs_type != "untyped"

        # Fall back to reader's return type or writer's param type
        reader_type = info[:reader]&.dig(:returns, :types)&.first
        return reader_type if reader_type && reader_type != "untyped" && reader_type != "Object"

        first_param = info[:writer]&.dig(:params)&.first
        writer_type = first_param&.dig(:types)&.first
        return writer_type if writer_type && writer_type != "untyped" && writer_type != "Object"

        nil
      end

      # Render a compact summary of private methods.
      def render_private_methods_summary(private_methods)
        return "" if private_methods.nil? || private_methods.empty?

        sorted = private_methods.sort_by { |m| [m[:scope] == :class ? 0 : 1, m[:name].to_s] }
        items  = sorted.map do |m|
          prefix = m[:scope] == :class ? "." : "#"
          line   = m[:line] ? ":#{m[:line]}" : ""
          "`#{prefix}#{m[:name]}`#{line}"
        end

        "---\n\n**Private:** #{items.join(', ')}"
      end

      def render_method(meth, context)
        display_name = method_display_name(meth)
        docstring    = if useful_docstring?(meth[:docstring])
                         @class_linker.linkify_docstring(meth[:docstring], context: context)
                       end

        params, return_line = render_params_and_return(meth)

        @template_renderer.render_method(
          display_name:  display_name,
          has_params:    meth[:params]&.any?,
          docstring:     docstring,
          params:        params,
          return_line:   return_line,
          examples:      meth[:examples] || [],
          behaviors:     @include_specs ? (meth[:spec_behaviors] || []).first(8) : [],
          spec_examples: @include_specs ? (meth[:spec_examples] || []).first(3) : [],
          inline_source: inline_source_for(meth)
        )
      end

      # Returns method source if it's short enough to display inline.
      # Prepends a location comment showing relative file path and line number.
      def inline_source_for(meth)
        return nil unless @inline_source_threshold&.positive?
        return nil unless meth[:source]

        body_lines = meth[:source_body_lines]
        return nil if body_lines.nil? || body_lines > @inline_source_threshold

        source = meth[:source]
        if meth[:file] && meth[:line]
          location = "# #{relative_path(meth[:file])} : ~#{meth[:line]}\n"
          "#{location}#{source}"
        else
          source
        end
      end

      def method_display_name(meth)
        return "#{meth[:class_name]}.new" if meth[:name] == :initialize
        return "#{meth[:class_name]}.#{meth[:name]}" if meth[:scope] == :class

        meth[:name].to_s
      end

      def useful_docstring?(docstring)
        return false if docstring.to_s.empty?
        return false if docstring.match?(/\AReturns the value of attribute \w+\.?\z/)

        true
      end

      # Render params and return together so they can share alignment width.
      def render_params_and_return(meth)
        params  = meth[:params] || []
        returns = meth[:returns]

        # Calculate param inners and max width
        max_name_len  = params.map { |p| clean_param_name(p[:name]).length }.max || 0
        param_inners  = params.map { |p| build_param_inner(p, max_name_len) }
        max_inner_len = param_inners.map(&:length).max || 0

        # Include return type in width calculation
        return_type   = extract_return_type(meth)
        max_inner_len = [max_inner_len, return_type&.length || 0].max if return_type

        param_lines = params.zip(param_inners).map { |p, inner| format_param_line(p, inner, max_inner_len) }
        return_line = render_return_line(returns, return_type, max_inner_len)

        [param_lines, return_line]
      end

      def build_param_inner(param, max_name_len)
        name     = clean_param_name(param[:name])
        prefix   = extract_param_prefix(param[:name])
        raw_type = param[:types]&.first
        type     = raw_type && raw_type != "untyped" ? " : #{normalize_type(raw_type)}" : ""
        default  = param[:default]
        padded   = name.ljust(max_name_len)

        default ? "#{prefix}#{padded}#{type} = #{default}" : "#{prefix}#{padded}#{type}"
      end

      def format_param_line(param, inner, max_inner_len)
        desc       = param[:text].to_s
        padded_sig = "⟨#{inner}⟩".ljust(max_inner_len + 2) # +2 for ⟨⟩

        desc.empty? ? "`#{padded_sig}`" : "`#{padded_sig}` — #{desc}"
      end

      def clean_param_name(name) = name.to_s.delete_prefix("*").delete_prefix("*").delete_prefix("&").chomp(":")

      def extract_param_prefix(name)
        str = name.to_s
        return "**" if str.start_with?("**")
        return "*" if str.start_with?("*")
        return "&" if str.start_with?("&")

        ""
      end

      def normalize_type(type) = type.tr("<", "[").tr(">", "]")

      def extract_return_type(meth)
        returns = meth[:returns]
        return nil unless returns

        type = returns[:types]&.first
        type = meth[:class_name] if meth[:name] == :initialize && type == "void"
        return nil if type.nil? || type == "void"

        normalize_type(type)
      end

      def render_return_line(returns, type, max_width)
        return nil unless type

        desc       = capitalize_first(returns[:text].to_s)
        padded_sig = type.ljust(max_width)

        desc.to_s.empty? ? "⟶ `#{padded_sig}`" : "⟶ `#{padded_sig}` — #{desc}"
      end

      def capitalize_first(str)
        return nil if str.nil? || str.strip.empty?

        s = str.strip
        s[0].upcase + s[1..]
      end

      def to_kebab_case(str)
        str.gsub(/([A-Za-z])([vV]\d+)/, '\1-\2')
           .gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
           .gsub(/([a-z\d])([A-Z])/, '\1-\2')
           .downcase
      end
    end
  end
end
