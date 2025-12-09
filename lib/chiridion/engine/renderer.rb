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
        templates_path: nil
      )
        @namespace_strip = namespace_strip
        @include_specs = include_specs
        @root = root
        @index_description = index_description || "Auto-generated from source code."
        @class_linker = ClassLinker.new(namespace_strip: namespace_strip)
        @github_linker = GithubLinker.new(repo: github_repo, branch: github_branch, root: root)
        @frontmatter_builder = FrontmatterBuilder.new(
          @class_linker,
          namespace_strip: namespace_strip,
          project_title: project_title
        )
        @template_renderer = TemplateRenderer.new(templates_path: templates_path)
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
          title: frontmatter[:title],
          description: @index_description,
          classes: classes,
          modules: modules
        )

        "#{render_frontmatter(frontmatter)}\n\n#{body}\n"
      end

      # Render class documentation.
      #
      # @param klass [Hash] Class data from Extractor
      # @return [String] Markdown documentation
      def render_class(klass)
        render_document(klass, include_mixins: true)
      end

      # Render module documentation.
      #
      # @param mod [Hash] Module data from Extractor
      # @return [String] Markdown documentation
      def render_module(mod)
        render_document(mod, include_mixins: false)
      end

      private

      def render_document(obj, include_mixins:)
        frontmatter = build_document_frontmatter(obj)
        docstring = @class_linker.linkify_docstring(obj[:docstring], context: obj[:path])

        body = @template_renderer.render_document(
          title: obj[:path],
          docstring: docstring,
          mixins: include_mixins ? render_mixins(obj) : nil,
          examples: obj[:examples] || [],
          spec_examples: render_spec_examples(obj),
          see_also: render_see_also(obj[:see_also], obj[:path]),
          constants_section: render_constants(obj[:constants]),
          methods_section: render_methods(obj[:methods], obj[:path])
        )

        "#{render_frontmatter(frontmatter)}\n\n#{body}\n"
      end

      def build_document_frontmatter(obj)
        frontmatter = @frontmatter_builder.build(obj)
        # Convert absolute paths to relative
        frontmatter[:source] = relative_path(frontmatter[:source])
        frontmatter[:source] = format_source_with_lines(frontmatter[:source], obj[:line], obj[:end_line])
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
      def render_frontmatter(fm)
        block_style_fields = %i[related inherited_by]

        lines = ["---"]
        fm.each do |key, value|
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
        stripped = @namespace_strip ? class_path.sub(/^#{Regexp.escape(@namespace_strip)}/, "") : class_path
        parts = stripped.split("::")
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

      def clean(code, class_path)
        code.gsub("described_class", class_path.split("::").last).strip
      end

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

        simple, complex = partition_constants(constants)

        constant_data = constants.map do |c|
          {
            name: c[:name],
            value: format_constant_value(c[:value], complex.include?(c)),
            docstring: c[:docstring].to_s,
            is_complex: complex.include?(c)
          }
        end

        complex_data = complex.map do |c|
          {
            name: c[:name],
            value: strip_freeze(c[:value]),
            docstring: c[:docstring].to_s
          }
        end

        @template_renderer.render_constants(
          constants: constant_data,
          complex_constants: complex_data
        )
      end

      def partition_constants(constants)
        constants.partition { |c| c[:value].to_s.count("\n") <= 1 }
      end

      def format_constant_value(value, is_complex)
        return "" if is_complex
        return "nil" if value.nil?

        strip_freeze(value.to_s).gsub("|", "\\|").gsub("\n", "<br />")
      end

      def strip_freeze(str)
        str.to_s.delete_suffix(".freeze")
      end

      def render_methods(methods, context)
        return "" if methods.nil? || methods.empty?

        rendered = methods.map { |m| render_method(m, context) }.join("\n\n---\n\n")
        "## Methods\n\n#{rendered}"
      end

      def render_method(meth, context)
        display_name = method_display_name(meth)
        docstring = useful_docstring?(meth[:docstring]) ? @class_linker.linkify_docstring(meth[:docstring], context: context) : nil

        @template_renderer.render_method(
          display_name: display_name,
          has_params: meth[:params]&.any?,
          docstring: docstring,
          params: render_params_with_types(meth[:params]),
          return_line: render_return_line(meth),
          examples: meth[:examples] || [],
          behaviors: @include_specs ? (meth[:spec_behaviors] || []).first(8) : [],
          spec_examples: @include_specs ? (meth[:spec_examples] || []).first(3) : []
        )
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

      def render_params_with_types(params)
        return [] if params.nil? || params.empty?

        max_name_len = params.map { |p| clean_param_name(p[:name]).length }.max
        params.map { |p| format_param(p, max_name_len) }
      end

      def format_param(param, max_name_len)
        name = clean_param_name(param[:name])
        prefix = extract_param_prefix(param[:name])
        type = normalize_type(param[:types]&.first || "untyped")
        default = param[:default]
        desc = param[:text].to_s
        padded = name.ljust(max_name_len)

        inner = default ? "#{prefix}#{padded} : #{type} = #{default}" : "#{prefix}#{padded} : #{type}"
        desc.empty? ? "⟨#{inner}⟩" : "⟨#{inner}⟩ → #{desc}"
      end

      def clean_param_name(name)
        name.to_s.delete_prefix("*").delete_prefix("*").delete_prefix("&").chomp(":")
      end

      def extract_param_prefix(name)
        str = name.to_s
        return "**" if str.start_with?("**")
        return "*" if str.start_with?("*")
        return "&" if str.start_with?("&")

        ""
      end

      def normalize_type(type)
        type.tr("<", "[").tr(">", "]")
      end

      def render_return_line(meth)
        returns = meth[:returns]
        return nil unless returns

        type = returns[:types]&.first
        type = meth[:class_name] if meth[:name] == :initialize && type == "void"
        return nil if type.nil? || type == "void"

        type = normalize_type(type)
        desc = returns[:text].to_s
        desc.empty? ? "→ #{type}" : "→ #{type} — #{desc}"
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
