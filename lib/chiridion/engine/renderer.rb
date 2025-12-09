# frozen_string_literal: true

module Chiridion
  class Engine
    # Renders documentation to markdown with wikilinks.
    #
    # Generates index files, class documentation, and module documentation
    # with [[wikilinks]] for cross-references between classes.
    class Renderer
      def initialize(namespace_strip, include_specs, github_repo: nil, github_branch: "main")
        @namespace_strip = namespace_strip
        @include_specs = include_specs
        @github_repo = github_repo
        @github_branch = github_branch
        @known_classes = {}
      end

      # Register known classes for cross-reference linking.
      #
      # @param structure [Hash] Documentation structure from Extractor
      def register_classes(structure)
        (structure[:classes] + structure[:modules]).each do |obj|
          @known_classes[obj[:path]] = obj
          # Also register short name
          short = obj[:path].split("::").last
          @known_classes[short] ||= obj
        end
      end

      # Render the documentation index.
      #
      # @param structure [Hash] Documentation structure from Extractor
      # @return [String] Markdown index
      def render_index(structure)
        <<~MD
          ---
          generated: #{Time.now.utc.strftime("%Y-%m-%d %H:%M UTC")}
          type: index
          ---

          # API Documentation

          > Auto-generated from source code.

          ## Classes

          #{structure[:classes].map { |c| "- [[#{link_path(c[:path])}|#{c[:path]}]]" }.join("\n")}

          ## Modules

          #{structure[:modules].map { |m| "- [[#{link_path(m[:path])}|#{m[:path]}]]" }.join("\n")}
        MD
      end

      # Render class documentation.
      #
      # @param klass [Hash] Class data from Extractor
      # @return [String] Markdown documentation
      def render_class(klass)
        render_document(klass, format_title(klass))
      end

      # Render module documentation.
      #
      # @param mod [Hash] Module data from Extractor
      # @return [String] Markdown documentation
      def render_module(mod)
        render_document(mod, mod[:path])
      end

      private

      def format_title(klass)
        if klass[:superclass] && klass[:superclass] != "Object"
          "#{klass[:path]} < #{link_class(klass[:superclass])}"
        else
          klass[:path]
        end
      end

      def render_document(obj, title)
        sections = []
        sections << render_mixins(obj)
        sections << render_examples(obj[:examples])
        sections << render_spec_examples(obj) if @include_specs
        sections << render_see_also(obj[:see_also])
        sections << render_constants(obj[:constants])
        sections << render_methods(obj[:methods])

        <<~MD
          #{render_frontmatter(obj)}

          # #{title}

          #{linkify(obj[:docstring])}

          #{sections.reject(&:empty?).join("\n\n")}
        MD
      end

      def render_frontmatter(obj)
        lines = ["---"]
        lines << "generated: #{Time.now.utc.strftime("%Y-%m-%d %H:%M UTC")}"
        lines << "source: #{format_source(obj)}"
        lines << "source_url: #{github_url(obj)}" if @github_repo
        lines << "type: #{obj[:type]}"
        lines << "parent: #{obj[:superclass]}" if obj[:superclass] && obj[:superclass] != "Object"
        lines << "---"
        lines.join("\n")
      end

      def format_source(obj)
        return obj[:file] unless obj[:line]

        if obj[:end_line] && obj[:end_line] != obj[:line]
          "#{obj[:file]}:#{obj[:line]}-#{obj[:end_line]}"
        else
          "#{obj[:file]}:#{obj[:line]}"
        end
      end

      def github_url(obj)
        return nil unless @github_repo && obj[:file]

        base = "https://github.com/#{@github_repo}/blob/#{@github_branch}/#{obj[:file]}"
        obj[:line] ? "#{base}#L#{obj[:line]}" : base
      end

      def render_mixins(obj)
        parts = []
        if obj[:includes]&.any?
          linked = obj[:includes].map { |m| link_class(m) }
          parts << "**Includes:** #{linked.join(", ")}"
        end
        if obj[:extends]&.any?
          linked = obj[:extends].map { |m| link_class(m) }
          parts << "**Extends:** #{linked.join(", ")}"
        end
        parts.join(" · ")
      end

      def render_see_also(see_tags)
        return "" if see_tags.nil? || see_tags.empty?

        links = see_tags.map do |tag|
          link = link_class(tag[:name])
          tag[:text].to_s.empty? ? link : "#{link} — #{tag[:text]}"
        end
        "**See also:** #{links.join(" · ")}"
      end

      def render_examples(examples)
        return "" if examples.nil? || examples.empty?

        parts = ["## Examples"]
        examples.each do |ex|
          parts << "**#{ex[:name]}**" unless ex[:name].to_s.empty?
          parts << "```ruby\n#{ex[:text]}\n```"
        end
        parts.join("\n\n")
      end

      def render_spec_examples(obj)
        return "" unless obj[:spec_examples]

        ex = obj[:spec_examples]
        return "" if ex[:lets].empty? && ex[:subjects].empty?

        parts = ["## Usage (from specs)"]
        ex[:subjects].each { |e| parts << "```ruby\n#{e[:code]}\n```" }
        ex[:lets].first(5).each { |e| parts << "**#{e[:name]}:** `#{e[:code]}`" }
        parts.join("\n\n")
      end

      def render_constants(constants)
        return "" if constants.nil? || constants.empty?

        parts = ["## Constants"]
        constants.each do |c|
          parts << "### `#{c[:name]}`"
          parts << c[:docstring] unless c[:docstring].empty?
          parts << "```ruby\n#{c[:name]} = #{c[:value]}\n```" if c[:value]
        end
        parts.join("\n\n")
      end

      def render_methods(methods)
        return "" if methods.nil? || methods.empty?

        class_methods = methods.select { |m| m[:scope] == :class }
        instance_methods = methods.select { |m| m[:scope] == :instance }

        parts = ["## Methods"]
        parts << render_method_group("Class Methods", class_methods) if class_methods.any?
        parts << render_method_group("Instance Methods", instance_methods) if instance_methods.any?
        parts.join("\n\n")
      end

      def render_method_group(title, methods)
        parts = ["### #{title}"]
        methods.each do |m|
          parts << render_method(m)
        end
        parts.join("\n\n")
      end

      def render_method(m)
        prefix = m[:scope] == :class ? "." : "#"
        sig = m[:rbs_type] || format_signature(m)

        parts = []
        parts << "#### `#{prefix}#{m[:name]}`"
        parts << "```rbs\n#{sig}\n```" if sig
        parts << linkify(m[:docstring]) unless m[:docstring].empty?
        parts << render_params(m[:params]) if m[:params]&.any?
        parts << render_return(m[:returns]) if m[:returns]
        parts << render_examples(m[:examples]) if m[:examples]&.any?
        parts.join("\n\n")
      end

      def format_signature(m)
        return nil if m[:params].nil? || m[:params].empty?

        params = m[:params].map do |p|
          type = p[:types]&.first || "untyped"
          "#{type} #{p[:name]}"
        end
        ret = m[:returns]&.dig(:types)&.first || "void"
        "(#{params.join(", ")}) -> #{ret}"
      end

      def render_params(params)
        return "" if params.empty?

        lines = params.map do |p|
          type = p[:types]&.first || "untyped"
          desc = p[:text] || ""
          "- `#{p[:name]}` (`#{type}`) #{desc}".strip
        end
        "**Parameters:**\n#{lines.join("\n")}"
      end

      def render_return(ret)
        return "" unless ret

        type = ret[:types]&.first || "untyped"
        desc = ret[:text] || ""
        "**Returns:** `#{type}` #{desc}".strip
      end

      # Convert class references in text to wikilinks.
      def linkify(text)
        return "" if text.nil? || text.empty?

        # Match {ClassName} or {Class::Name} patterns from YARD
        text.gsub(/\{([A-Z][\w:]+)\}/) do |_match|
          class_name = Regexp.last_match(1)
          link_class(class_name)
        end
      end

      # Create a wikilink for a class/module.
      def link_class(class_path)
        return class_path unless @known_classes.key?(class_path)

        "[[#{link_path(class_path)}|#{class_path}]]"
      end

      # Convert class path to file path for wikilinks.
      def link_path(class_path)
        stripped = @namespace_strip ? class_path.sub(/^#{Regexp.escape(@namespace_strip)}/, "") : class_path
        parts = stripped.split("::")
        kebab_parts = parts.map { |p| to_kebab_case(p) }
        kebab_parts.join("/")
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
