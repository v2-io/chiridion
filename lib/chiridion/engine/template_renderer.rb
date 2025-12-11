# frozen_string_literal: true

require "liquid"

module Chiridion
  class Engine
    # Renders documentation using Liquid templates.
    #
    # Templates are loaded from the gem's templates/ directory by default,
    # but can be overridden by specifying a custom templates_path.
    #
    # Available templates:
    # - index.liquid: Documentation index page
    # - document.liquid: Class/module documentation
    # - method.liquid: Individual method documentation
    # - constants.liquid: Constants table and complex constant sections
    class TemplateRenderer
      # Custom Liquid filters for documentation rendering.
      module Filters
        # Escape pipe characters for markdown table cells.
        def escape_pipes(input)
          return "" if input.nil?

          input.to_s.gsub("|", "\\|")
        end

        # Remove newlines for single-line table cells.
        def strip_newlines(input)
          return "" if input.nil?

          input.to_s.gsub(/\s*\n\s*/, " ").strip
        end

        # Convert to kebab case for file paths.
        def kebab_case(input)
          return "" if input.nil?

          input.to_s
               .gsub(/([A-Za-z])([vV]\d+)/, '\1-\2')
               .gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
               .gsub(/([a-z\d])([A-Z])/, '\1-\2')
               .downcase
        end

        # Strip @rbs! blocks from docstrings (type metadata shouldn't be in docs).
        def strip_rbs_blocks(input)
          return "" if input.nil?

          input.to_s.gsub(/@rbs![\s\S]*?(?=\n\n|\z)/, "").strip
        end

        # Normalize markdown headers to be subordinate to a given level.
        # Usage: {{ docstring | normalize_headers: 4 }}
        # Adjusts all headers so the minimum level becomes the specified level.
        def normalize_headers(input, min_level = 3)
          return "" if input.nil? || input.to_s.empty?

          text  = input.to_s
          lines = text.lines

          # Find the minimum header level in the text
          header_levels = lines.filter_map do |line|
            match = line.match(/^(#+)\s/)
            match[1].length if match
          end

          return text if header_levels.empty?

          current_min = header_levels.min
          offset      = min_level.to_i - current_min
          return text if offset <= 0

          # Prepend offset number of # to all header lines
          prefix = "#" * offset
          lines.map do |line|
            if line.match?(/^#+\s/)
              prefix + line
            else
              line
            end
          end.join
        end
      end

      def initialize(templates_path: nil)
        @templates_path = templates_path || default_templates_path
        @templates      = {}
        @environment    = Liquid::Environment.build do |env|
          env.register_filter(Filters)
        end
      end

      # Render the index template.
      #
      # @param title [String] Project title
      # @param description [String] Index description
      # @param classes [Array<Hash>] Class objects with :path and :link_path
      # @param modules [Array<Hash>] Module objects with :path and :link_path
      # @return [String] Rendered markdown
      def render_index(title:, description:, classes:, modules:)
        render("index", {
                 "title"       => title,
                 "description" => description,
                 "classes"     => stringify_keys(classes),
                 "modules"     => stringify_keys(modules)
               })
      end

      # Render a class or module document.
      #
      # @param title [String] Class/module full path
      # @param docstring [String] Main documentation (linkified)
      # @param mixins [String, nil] Mixin line (e.g., "**Includes:** ...")
      # @param examples [Array<Hash>] YARD examples with :name and :text
      # @param spec_examples [String, nil] Rendered spec examples section
      # @param see_also [String, nil] See also links
      # @param constants_section [String] Rendered constants section
      # @param types_section [String] Rendered types section (type aliases used by this class)
      # @param attributes_section [String] Rendered attributes section
      # @param methods_section [String] Rendered methods section
      # @return [String] Rendered markdown
      def render_document(
        title:,
        docstring:,
        mixins: nil,
        examples: [],
        spec_examples: nil,
        see_also: nil,
        constants_section: "",
        types_section: "",
        attributes_section: "",
        methods_section: ""
      )
        render("document", {
                 "title"              => title,
                 "docstring"          => docstring,
                 "mixins"             => mixins,
                 "examples"           => stringify_keys(examples),
                 "spec_examples"      => spec_examples,
                 "see_also"           => see_also,
                 "constants_section"  => constants_section,
                 "types_section"      => types_section,
                 "attributes_section" => attributes_section,
                 "methods_section"    => methods_section
               })
      end

      # Render a single method.
      #
      # @param display_name [String] Method name (with class prefix if needed)
      # @param has_params [Boolean] Whether method has parameters
      # @param docstring [String, nil] Method description
      # @param params [Array<String>] Formatted parameter lines
      # @param return_line [String, nil] Formatted return line
      # @param examples [Array<Hash>] YARD examples
      # @param behaviors [Array<String>] Spec behavior descriptions
      # @param spec_examples [Array<Hash>] Spec code examples
      # @param inline_source [String, nil] Method source code to display inline
      # @return [String] Rendered markdown
      def render_method(
        display_name:,
        has_params: false,
        docstring: nil,
        params: [],
        return_line: nil,
        examples: [],
        behaviors: [],
        spec_examples: [],
        inline_source: nil
      )
        render("method", {
                 "display_name"  => display_name,
                 "has_params"    => has_params,
                 "docstring"     => docstring,
                 "params"        => params,
                 "return_line"   => return_line,
                 "examples"      => stringify_keys(examples),
                 "behaviors"     => behaviors,
                 "spec_examples" => stringify_keys(spec_examples),
                 "inline_source" => inline_source
               })
      end

      # Render the methods section with separators.
      #
      # @param methods [Array<String>] Pre-rendered method strings
      # @return [String] Rendered markdown
      def render_methods(methods:) = render("methods", {
                                              "methods" => methods
                                            })

      # Render the constants section.
      #
      # @param constants [Array<Hash>] Constants with :name, :value, :docstring, :is_complex
      # @param complex_constants [Array<Hash>] Complex constants for expanded rendering
      # @return [String] Rendered markdown
      def render_constants(constants:, complex_constants:)
        render("constants", {
                 "constants"         => stringify_keys(constants),
                 "complex_constants" => stringify_keys(complex_constants)
               })
      end

      # Render the types section (type aliases used by a class/module).
      #
      # @param types [Array<Hash>] Types with :name, :definition, :description, :namespace
      # @return [String] Rendered markdown
      def render_types(types:) = render("types", {
                                          "types" => stringify_keys(types)
                                        })

      # Render the type aliases reference page.
      #
      # @param title [String] Page title
      # @param description [String] Page description
      # @param namespaces [Array<Hash>] Namespaces with :name and :types arrays
      # @return [String] Rendered markdown
      def render_type_aliases(title:, description:, namespaces:)
        render("type_aliases", {
                 "title"       => title,
                 "description" => description,
                 "namespaces"  => stringify_keys(namespaces)
               })
      end

      private

      def default_templates_path = File.expand_path("../../../templates", __dir__)

      def render(template_name, variables)
        template = load_template(template_name)
        template.render(variables).strip
      end

      def load_template(name)
        @templates[name] ||= begin
          path = File.join(@templates_path, "#{name}.liquid")
          raise "Template not found: #{path}" unless File.exist?(path)

          Liquid::Template.parse(File.read(path), environment: @environment)
        end
      end

      # Convert symbol keys to string keys for Liquid compatibility.
      def stringify_keys(obj)
        case obj
        when Array
          obj.map { |item| stringify_keys(item) }
        when Hash
          obj.transform_keys(&:to_s).transform_values { |v| stringify_keys(v) }
        else
          obj
        end
      end
    end
  end
end
