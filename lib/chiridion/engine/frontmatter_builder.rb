# frozen_string_literal: true

require "time"

module Chiridion
  class Engine
    # Builds enhanced YAML frontmatter for documentation files.
    #
    # Generates Obsidian-compatible frontmatter with navigation aids,
    # discovery metadata, and search-friendly fields. Each documentation
    # file gets frontmatter that enables:
    #
    # - **Navigation**: parent links for breadcrumb traversal
    # - **Discovery**: tags for filtering, related links for exploration
    # - **Search**: aliases for finding by short name, description for preview
    class FrontmatterBuilder
      def initialize(class_linker, namespace_strip: nil, project_title: "API Documentation")
        @class_linker         = class_linker
        @namespace_strip      = namespace_strip
        @project_title        = project_title
        @inheritance_children = {} # Maps parent class path -> array of child class paths
      end

      # Pre-compute inheritance relationships from full structure.
      #
      # Must be called before build() to populate inherited-by fields.
      # Scans all classes to build parent->children mapping.
      #
      # @param structure [Hash] Full documentation structure from Extractor
      def register_inheritance(structure)
        @inheritance_children = {}
        structure[:classes].each do |klass|
          parent = klass[:superclass]
          next unless parent && documentable_class?(parent)

          @inheritance_children[parent] ||= []
          @inheritance_children[parent] << klass[:path]
        end
      end

      # Build frontmatter hash for a class or module.
      #
      # @param obj [Hash] Extracted object data from Extractor
      # @return [Hash] Frontmatter fields in render order
      def build(obj)
        {
          generated:    Time.now.utc.iso8601,
          title:        obj[:path],
          type:         obj[:type].to_s, # :class or :module
          source:       relative_path(obj[:file]),
          description:  extract_description(obj[:docstring]),
          inherits:     build_inherits_link(obj[:superclass]),
          parent:       build_parent_link(obj[:path]),
          inherited_by: build_inherited_by_links(obj[:path]),
          includes:     build_mixin_list(obj[:includes]),
          extends:      build_mixin_list(obj[:extends]),
          rbs:          obj[:rbs_file] ? relative_path(obj[:rbs_file]) : nil,
          tags:         build_tags(obj[:path]),
          aliases:      build_aliases(obj[:path]),
          constants:    build_constant_list(obj[:constants]),
          methods:      build_method_list(obj[:methods], obj[:path]),
          related:      build_related(obj)
        }.compact
      end

      # Build frontmatter for index page.
      #
      # @return [Hash] Minimal frontmatter for index
      def build_index
        {
          generated: Time.now.utc.iso8601,
          title:     @project_title,
          tags:      %w[index api-reference]
        }
      end

      private

      def documentable_class?(class_path)
        return true unless @namespace_strip

        class_path.start_with?(@namespace_strip)
      end

      # Extract first sentence as description.
      def extract_description(docstring)
        return nil if docstring.nil? || docstring.strip.empty?

        # Take first paragraph (up to blank line)
        first_para = docstring.split(/\n\s*\n/).first&.strip
        return nil if first_para.nil? || first_para.empty?

        # Take first sentence (period/exclamation/question followed by space or end)
        first_sentence = first_para.match(/^(.+?[.!?])(?:\s|$)/m)&.[](1)
        result         = first_sentence || first_para

        # Strip markdown formatting: **bold**, `code`, [[links]]
        result = result.gsub(/\*\*(.+?)\*\*/, '\1') # bold
        result = result.gsub(/`(.+?)`/, '\1') # inline code
        result = result.gsub(/\[\[.+?\|(.+?)\]\]/, '\1') # wikilinks with alias
        result = result.gsub(/\[\[(.+?)\]\]/, '\1') # wikilinks without alias

        result.strip
      end

      # Build wikilink to parent namespace documentation.
      def build_parent_link(path)
        parts          = path.split("::")
        # Strip namespace prefix to count depth
        stripped_parts = @namespace_strip ? path.sub(/^#{Regexp.escape(@namespace_strip)}/, "").split("::") : parts
        return nil if stripped_parts.size <= 1 # Top-level has no documentable parent

        parent_parts = parts[0..-2]
        parent_path  = parent_parts.join("::")

        # Build link path (skip namespace prefix for file path)
        link_parts = if @namespace_strip
                       parent_path.sub(/^#{Regexp.escape(@namespace_strip)}/,
                                       "").split("::")
                     else
                       parent_parts
                     end
        link_path  = link_parts.map { |p| to_kebab_case(p) }.join("/")

        "\"[[#{link_path}|#{parent_path}]]\""
      end

      # Build superclass reference (linked if internal, plain text if external).
      def build_inherits_link(superclass)
        return nil unless superclass

        linkify_class(superclass) || superclass
      end

      # Build wikilinks to classes that inherit from this one.
      def build_inherited_by_links(path)
        children = @inheritance_children[path]
        return nil if children.nil? || children.empty?

        children.sort.filter_map { |child| linkify_class(child) }
      end

      # Build list of included/extended modules (short names only).
      def build_mixin_list(mixins)
        return nil if mixins.nil? || mixins.empty?

        mixins.map { |m| m.split("::").last }
      end

      # Build list of constant names.
      def build_constant_list(constants)
        return nil if constants.nil? || constants.empty?

        constants.map { |c| c[:name].to_s }
      end

      # Build list of method names for frontmatter.
      def build_method_list(methods, class_path)
        return nil if methods.nil? || methods.empty?

        class_name = class_path.split("::").last

        class_methods = methods.select { |m| m[:scope] == :class }
                               .map { |m| format_method_name("#{class_name}.#{m[:name]}") }
                               .sort

        instance_methods = methods.reject { |m| m[:scope] == :class }
                                  .map { |m| format_method_name(m[:name].to_s) }
                                  .sort

        class_methods + instance_methods
      end

      # Quote method names with special characters for YAML safety.
      def format_method_name(name) = name.match?(/[\[\]{}:,#&*!|>'"%@`]/) ? "'#{name}'" : name

      # Generate tags from namespace hierarchy.
      def build_tags(path)
        stripped = @namespace_strip ? path.sub(/^#{Regexp.escape(@namespace_strip)}/, "") : path
        parts    = stripped.split("::")
        parts.map { |p| to_kebab_case(p) }
      end

      # Build aliases for search discovery.
      def build_aliases(path)
        parts      = path.split("::")
        short_name = parts.last
        short_name == path ? [] : [short_name]
      end

      # Build related links from see_also, includes, extends, superclass.
      def build_related(obj)
        related = []

        # Add see_also references
        obj[:see_also]&.each do |see|
          link = linkify_class(see[:name])
          related << link if link
        end

        # Add mixins
        obj[:includes]&.each do |mixin|
          link = linkify_class(mixin)
          related << link if link
        end

        obj[:extends]&.each do |mixin|
          link = linkify_class(mixin)
          related << link if link
        end

        # Add superclass (if not Object/BasicObject)
        if obj[:superclass] && !%w[Object BasicObject].include?(obj[:superclass])
          link = linkify_class(obj[:superclass])
          related << link if link
        end

        related.empty? ? nil : related.uniq
      end

      # Convert class name to wikilink if we document it.
      def linkify_class(class_name)
        return nil unless documentable_class?(class_name)

        stripped  = @namespace_strip ? class_name.sub(/^#{Regexp.escape(@namespace_strip)}/, "") : class_name
        link_path = stripped.split("::")
                            .map { |p| to_kebab_case(p) }
                            .join("/")

        "\"[[#{link_path}|#{class_name}]]\""
      end

      def relative_path(absolute_path)
        return absolute_path unless absolute_path

        # Remove project root prefix if present
        absolute_path
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
