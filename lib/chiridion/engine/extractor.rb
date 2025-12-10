# frozen_string_literal: true

require "set"

module Chiridion
  class Engine
    # Extracts documentation structure from YARD registry.
    #
    # Parses Ruby source using YARD and builds a structured representation
    # of classes, modules, methods, and constants for documentation generation.
    # Merges RBS type signatures when available.
    class Extractor
      def initialize(rbs_types, spec_examples, namespace_filter, logger = nil, rbs_file_namespaces: {}, type_aliases: {})
        @rbs_types = rbs_types
        @spec_examples = spec_examples
        @namespace_filter = namespace_filter
        @logger = logger
        @type_merger = TypeMerger.new(logger)
        @rbs_file_namespaces = rbs_file_namespaces || {}
        @type_aliases = type_aliases || {}
        @type_alias_lookup = build_type_alias_lookup
      end

      # Extract documentation structure from YARD registry.
      #
      # @param registry [YARD::Registry] Parsed YARD registry
      # @param source_filter [Array<String>, nil] If provided, only objects from these
      #   source files are marked for regeneration. All objects are still extracted
      #   (for index generation), but only filtered ones get full documentation.
      # @return [Hash] Structure with :namespaces, :classes, :modules keys
      def extract(registry, source_filter: nil)
        structure = { namespaces: [], classes: [], modules: [] }
        @source_filter = source_filter&.map { |f| File.expand_path(f) }

        registry.all(:class, :module).each do |obj|
          next unless should_document?(obj)

          doc = extract_object(obj)
          structure[:classes] << doc if obj.is_a?(YARD::CodeObjects::ClassObject)
          structure[:modules] << doc if obj.is_a?(YARD::CodeObjects::ModuleObject)
        end

        structure
      end

      private

      def should_document?(obj)
        return true unless @namespace_filter

        obj.path.start_with?(@namespace_filter)
      end

      def extract_object(obj)
        path = obj.path
        needs_regen = needs_regeneration?(obj)
        methods = needs_regen ? extract_methods(obj, path) : []

        {
          name: obj.name,
          path: path,
          type: obj.type,
          docstring: clean_docstring(obj.docstring.to_s),
          file: obj.file,
          line: obj.line,
          end_line: compute_end_line(obj),
          examples: needs_regen ? obj.tags(:example).map { |t| { name: t.name, text: t.text } } : [],
          see_also: needs_regen ? extract_see_tags(obj) : [],
          methods: methods,
          constants: needs_regen ? extract_constants(obj, path) : [],
          includes: obj.instance_mixins.map(&:path),
          extends: obj.class_mixins.map(&:path),
          superclass: obj.respond_to?(:superclass) ? obj.superclass&.path : nil,
          rbs_file: needs_regen ? find_rbs_file(path) : nil,
          spec_examples: needs_regen ? @spec_examples[path] : nil,
          referenced_types: needs_regen ? collect_referenced_types(methods) : [],
          needs_regeneration: needs_regen
        }
      end

      def extract_see_tags(obj)
        obj.tags(:see).map { |t| { name: t.name, text: t.text } }
      end

      def compute_end_line(obj)
        return nil unless obj.source

        obj.line + obj.source.lines.count - 1
      end

      def needs_regeneration?(obj)
        return true if @source_filter.nil?

        source_file = obj.file && File.expand_path(obj.file)
        return true if @source_filter.include?(source_file)

        # Also check if any filtered source file has @rbs content for this namespace.
        # This handles files like shared_types.rb that reopen a module with @rbs!
        # blocks but no new methods/classes - YARD attributes them to the original
        # module definition, so we need to check the rbs_file_namespaces mapping.
        obj_path = obj.path
        @source_filter.any? do |filtered_file|
          namespaces = @rbs_file_namespaces[filtered_file]
          namespaces&.include?(obj_path)
        end
      end

      def extract_constants(obj, class_path)
        obj.constants.map do |c|
          { name: c.name, value: c.value, docstring: clean_docstring(c.docstring.to_s), class_path: class_path }
        end
      end

      def clean_docstring(str)
        return "" if str.nil? || str.empty?

        str.lines
           .reject { |line| line.strip.match?(/^rubocop:(disable|enable|todo)\b/i) }
           .join
           .strip
      end

      def extract_methods(obj, class_path)
        instance_methods = obj.meths(scope: :instance, visibility: :public).map do |m|
          extract_method(m, class_path, :instance)
        end

        class_methods = obj.meths(scope: :class, visibility: :public).map do |m|
          extract_method(m, class_path, :class)
        end

        class_methods + instance_methods
      end

      def extract_method(meth, class_path, scope)
        rbs_data = @rbs_types.dig(class_path, meth.name.to_s)
        yard_params = extract_params(meth)
        yard_return = extract_return(meth)
        {
          name: meth.name,
          signature: meth.signature,
          docstring: clean_docstring(meth.docstring.to_s),
          params: @type_merger.merge_params(yard_params, rbs_data, class_path, meth.name),
          returns: @type_merger.merge_return(yard_return, rbs_data, class_path, meth.name),
          examples: meth.tags(:example).map { |t| { name: t.name, text: t.text } },
          visibility: meth.visibility,
          scope: scope,
          class_name: class_path.split("::").last,
          rbs_type: rbs_data&.dig(:full),
          spec_examples: method_spec_examples(class_path, meth.name),
          spec_behaviors: method_spec_behaviors(class_path, meth.name)
        }
      end

      def extract_params(meth)
        param_tags = meth.tags(:param).to_h { |t| [t.name, { types: t.types, text: t.text }] }

        meth.parameters.map do |name, default|
          param_name = name.to_s.delete_prefix("*").delete_prefix("**").delete_prefix("&")
          tag_info = param_tags[param_name] || {}
          { name: name, types: tag_info[:types], text: tag_info[:text], default: default }
        end
      end

      def extract_return(meth)
        tag = meth.tag(:return)
        tag ? { types: tag.types, text: tag.text } : nil
      end

      def method_spec_examples(class_path, method_name)
        lookup_spec_data(class_path, :method_examples, method_name)
      end

      def method_spec_behaviors(class_path, method_name)
        lookup_spec_data(class_path, :behaviors, method_name)
      end

      def lookup_spec_data(class_path, category, method_name)
        return [] unless @spec_examples[class_path]

        @spec_examples[class_path][category][".#{method_name}"] ||
          @spec_examples[class_path][category]["##{method_name}"] || []
      end

      def find_rbs_file(class_path)
        parts = class_path.split("::").map { |part| to_snake_case(part) }
        path = "sig/#{parts.join("/")}.rbs"
        File.exist?(path) ? path : nil
      end

      def to_snake_case(str)
        str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      end

      # Build flat lookup of type alias names to their full definitions.
      # Allows quick matching when scanning method signatures.
      def build_type_alias_lookup
        lookup = {}
        @type_aliases.each do |namespace, types|
          types.each do |type_info|
            lookup[type_info[:name]] = type_info.merge(namespace: namespace)
          end
        end
        lookup
      end

      # Scan method signatures for references to known type aliases.
      # Returns array of type definitions used by this class's methods.
      def collect_referenced_types(methods)
        return [] if @type_alias_lookup.empty? || methods.empty?

        referenced_names = Set.new

        methods.each do |meth|
          # Scan param types
          meth[:params]&.each do |param|
            extract_type_names(param[:types]).each { |name| referenced_names.add(name) }
          end

          # Scan return type
          if meth[:returns]
            extract_type_names(meth[:returns][:types]).each { |name| referenced_names.add(name) }
          end
        end

        # Look up full definitions for referenced type names
        referenced_names
          .filter_map { |name| @type_alias_lookup[name] }
          .sort_by { |t| t[:name] }
      end

      # Extract potential type alias names from type strings.
      # Handles types like "filter_value", "Array[filter_value]", "Hash[Symbol, actor]"
      def extract_type_names(types)
        return [] unless types

        Array(types).flat_map do |type_str|
          # Extract all word tokens that could be type alias names
          type_str.to_s.scan(/\b([a-z_][a-z0-9_]*)\b/i).flatten
        end
      end
    end
  end
end
