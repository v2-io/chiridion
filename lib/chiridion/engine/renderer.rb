# frozen_string_literal: true

module Chiridion
  class Engine
    # Renders documentation to Obsidian-compatible markdown.
    #
    # Generates index files, class documentation, and module documentation
    # with wikilinks for cross-references within the Obsidian vault.
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
        index_description: nil
      )
        @namespace_strip = namespace_strip
        @include_specs = include_specs
        @root = root
        @index_description = index_description || "Auto-generated from source code."
        @class_linker = ClassLinker.new(namespace_strip: namespace_strip)
        @constant_renderer = ConstantRenderer.new
        @method_renderer = MethodRenderer.new(include_specs, class_linker: @class_linker)
        @github_linker = GithubLinker.new(repo: github_repo, branch: github_branch, root: root)
        @frontmatter_builder = FrontmatterBuilder.new(
          @class_linker,
          namespace_strip: namespace_strip,
          project_title: project_title
        )
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
        <<~MD
          #{render_frontmatter(frontmatter)}

          # #{frontmatter[:title]}

          > #{@index_description}

          ## Classes

          #{structure[:classes].map { |c| "- [[#{link(c[:path])}|#{c[:path]}]]" }.join("\n")}

          ## Modules

          #{structure[:modules].map { |m| "- [[#{link(m[:path])}|#{m[:path]}]]" }.join("\n")}
        MD
      end

      # Render class documentation.
      #
      # @param klass [Hash] Class data from Extractor
      # @return [String] Markdown documentation
      def render_class(klass)
        title = format_class_title(klass)
        sections = build_sections(klass, include_mixins: true)
        render_document(klass, title, sections)
      end

      # Render module documentation.
      #
      # @param mod [Hash] Module data from Extractor
      # @return [String] Markdown documentation
      def render_module(mod)
        sections = build_sections(mod, include_mixins: false)
        render_document(mod, mod[:path], sections)
      end

      private

      # Format class title (just the path - inheritance is in frontmatter).
      def format_class_title(klass)
        klass[:path]
      end

      def build_sections(obj, include_mixins:)
        parts = []
        parts << render_mixins(obj) if include_mixins
        parts << render_yard_examples(obj[:examples])
        parts << render_spec_examples(obj)
        parts << render_see_also(obj[:see_also], obj[:path])
        # ToC removed - now in frontmatter (constants:, methods:)
        parts << @constant_renderer.render(obj[:constants])
        parts << render_methods(obj[:methods], obj[:path])
        parts.reject(&:empty?).join("\n\n")
      end

      def render_document(obj, title, sections)
        frontmatter = @frontmatter_builder.build(obj)
        # Convert absolute paths to relative
        frontmatter[:source] = relative_path(frontmatter[:source])
        frontmatter[:source] = format_source_with_lines(frontmatter[:source], obj[:line], obj[:end_line])
        frontmatter[:source_url] = @github_linker.url(
          frontmatter[:source].split(":").first,
          obj[:line],
          obj[:end_line]
        )
        docstring = @class_linker.linkify_docstring(obj[:docstring], context: obj[:path])
        <<~MD
          #{render_frontmatter(frontmatter)}

          # #{title}

          #{docstring}

          #{sections}
        MD
      end

      # Render frontmatter hash to YAML.
      #
      # Uses flow style [a, b, c] for compact arrays (methods, constants, tags).
      # Uses block style for arrays with wikilinks (related, inherited_by).
      # Omits nil values.
      def render_frontmatter(fm)
        # Fields that should use block style (contain wikilinks or long values)
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
        return "" unless klass[:includes].any? || klass[:extends].any?

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
        return "" if see_tags.nil? || see_tags.empty?

        links = see_tags.map do |tag|
          link = @class_linker.link(tag[:name], context: context)
          tag[:text].to_s.empty? ? link : "#{link} — #{tag[:text]}"
        end
        "**See also:** #{links.join(' · ')}"
      end

      def render_yard_examples(examples)
        return "" if examples.nil? || examples.empty?

        parts = ["## Example"]
        examples.each do |ex|
          parts << "**#{ex[:name]}**" unless ex[:name].to_s.empty?
          parts << "```ruby\n#{ex[:text]}\n```"
        end
        parts.join("\n\n")
      end

      def render_spec_examples(obj)
        return "" unless @include_specs && obj[:spec_examples]

        ex = obj[:spec_examples]
        return "" if ex[:lets].empty? && ex[:subjects].empty?

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

      def render_methods(methods, context)
        return "" if methods.empty?

        rendered = methods.map { |m| @method_renderer.render(m, context: context) }.join("\n\n\n---\n")
        "## Methods\n\n#{rendered}"
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
