# frozen_string_literal: true

module Chiridion
  class Engine
    # Converts class/module references to Obsidian wikilinks.
    #
    # Handles various reference formats:
    # - Full paths: `Autopax::Foo::Bar` → `[[foo/bar|Bar]]`
    # - YARD curly braces: `{Extractor}` → `[[extractor|Extractor]]`
    # - Relative names: `Writer` → `[[writer|Writer]]` (within same namespace)
    class ClassLinker
      # @return [Hash<String, String>] Known classes mapped to doc paths
      attr_reader :known_classes

      # @return [String, nil] Namespace prefix to strip from paths
      attr_reader :namespace_strip

      def initialize(namespace_strip: nil)
        @namespace_strip = namespace_strip
        @known_classes = {}
      end

      # Register known classes from the documentation structure.
      #
      # @param structure [Hash] Documentation structure from Extractor
      def register_classes(structure)
        (structure[:classes] + structure[:modules]).each do |obj|
          path = obj[:path]
          @known_classes[path] = doc_path(path)
          # Also register short name for relative lookups
          short_name = path.split("::").last
          @known_classes[short_name] ||= doc_path(path)
        end
      end

      # Convert a class path to a wikilink.
      #
      # @param class_path [String] Full or relative class path
      # @param context [String, nil] Current class context for relative resolution
      # @return [String] Wikilink like `[[path|Name]]` or original if not found
      def link(class_path, context: nil)
        display_name = class_path.split("::").last
        resolved = resolve(class_path, context: context)
        return display_name unless resolved

        "[[#{resolved}|#{display_name}]]"
      end

      # Process a docstring, converting {Class} references to wikilinks.
      #
      # @param text [String] Docstring text
      # @param context [String, nil] Current class context
      # @return [String] Text with {Class} converted to wikilinks
      def linkify_docstring(text, context: nil)
        return text if text.nil? || text.empty?

        text.gsub(/\{([A-Z][\w:]*)\}/) do |_match|
          class_ref = Regexp.last_match(1)
          link(class_ref, context: context)
        end
      end

      # Convert a type annotation to include wikilinks where possible.
      #
      # Returns formatted string with backticks around non-link parts.
      # Wikilinks must be outside backticks to render properly.
      #
      # @param type_str [String] Type like `Array<Autopax::Foo>` or `Hash{String => Bar}`
      # @param context [String, nil] Current class context
      # @return [String] Formatted type with proper backtick placement
      def linkify_type(type_str, context: nil)
        return "`Object`" if type_str.nil? || type_str.empty?

        segments = build_type_segments(type_str, context: context)
        format_type_segments(segments)
      end

      # Check if a class is a known documentable class.
      #
      # @param class_name [String] Class name to check
      # @return [Boolean]
      def known?(class_name)
        @known_classes.key?(class_name)
      end

      SKIP_TYPES = %w[Array Hash String Integer Float Symbol Boolean Object TrueClass FalseClass NilClass Proc
                      Class Module Numeric Enumerable Comparable void untyped nil self].freeze
      private_constant :SKIP_TYPES

      def skip_type?(class_ref)
        SKIP_TYPES.include?(class_ref)
      end

      private

      # Build segments from type string, identifying linkable class refs.
      def build_type_segments(type_str, context:)
        segments = []
        last_end = 0

        type_str.scan(/\b([A-Z]\w*(?:::[A-Z]\w*)*)\b/) do
          class_ref = Regexp.last_match(1)
          match_start = Regexp.last_match.begin(0)
          match_end = Regexp.last_match.end(0)

          segments << [:text, type_str[last_end...match_start]] if match_start > last_end
          segments << segment_for_class(class_ref, context: context)
          last_end = match_end
        end

        segments << [:text, type_str[last_end..]] if last_end < type_str.length
        segments
      end

      # Create segment for a class reference (link or text).
      def segment_for_class(class_ref, context:)
        return [:text, class_ref] if skip_type?(class_ref)

        resolved = resolve(class_ref, context: context)
        return [:text, class_ref] unless resolved

        [:link, "[[#{resolved}|#{class_ref.split('::').last}]]"]
      end

      # Format segments into final string with proper backtick placement.
      def format_type_segments(segments)
        return "`Object`" if segments.empty?
        return format_pure_text(segments) unless segments.any? { |type, _| type == :link }
        return segments.first.last if pure_link?(segments)

        format_mixed_segments(segments)
      end

      def format_pure_text(segments)
        "`#{segments.map(&:last).join}`"
      end

      def pure_link?(segments)
        segments.size == 1 && segments.first.first == :link
      end

      # Format mixed content: wrap text in backticks, leave links bare.
      def format_mixed_segments(segments)
        result = []
        text_buffer = +""

        segments.each do |type, content|
          if type == :text
            text_buffer << content
          else
            result << "`#{text_buffer}`" unless text_buffer.empty?
            text_buffer.clear
            result << content
          end
        end

        result << "`#{text_buffer}`" unless text_buffer.empty?
        result.join
      end

      # Resolve a class reference to its documentation path.
      def resolve(class_ref, context: nil)
        # Try exact match first
        return @known_classes[class_ref] if @known_classes[class_ref]

        # Try with namespace prefix
        if @namespace_strip
          full_path = "#{@namespace_strip}#{class_ref}"
          return @known_classes[full_path] if @known_classes[full_path]
        end

        # Try relative to context
        if context
          relative_path = "#{context}::#{class_ref}"
          return @known_classes[relative_path] if @known_classes[relative_path]

          # Try parent namespace
          parent = context.split("::")[0..-2].join("::")
          sibling_path = "#{parent}::#{class_ref}"
          return @known_classes[sibling_path] if @known_classes[sibling_path]
        end

        nil
      end

      # Convert class path to documentation file path.
      def doc_path(class_path)
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
