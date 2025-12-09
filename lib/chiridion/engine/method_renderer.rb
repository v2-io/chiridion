# frozen_string_literal: true

module Chiridion
  class Engine
    # Renders individual method documentation to markdown.
    #
    # Optimized for agent consumption: unified signature/params format.
    # Format:
    #   ### method_name(...)
    #   Description here.
    #   ⟨name : Type = default⟩ → description
    #   → ReturnType
    class MethodRenderer
      def initialize(include_specs, class_linker: nil)
        @include_specs = include_specs
        @class_linker = class_linker
      end

      # Render a method to markdown.
      #
      # @param meth [Hash] Method data from Extractor
      # @param context [String, nil] Current class context for link resolution
      # @return [String] Markdown documentation
      def render(meth, context: nil)
        parts = [render_header(meth)]
        parts << linkify_docstring(meth[:docstring], context) if useful_docstring?(meth[:docstring])
        parts << render_unified_signature(meth)
        parts.concat(render_examples(meth[:examples]))
        parts.concat(render_behaviors(meth[:spec_behaviors]))
        parts.concat(render_method_specs(meth[:spec_examples]))
        parts.compact.join("\n\n")
      end

      private

      # Header: ClassName.method(...) or method_name(...)
      def render_header(meth)
        has_params = meth[:params]&.any?
        suffix = has_params ? "(...)" : ""
        name = method_display_name(meth)
        "### #{name}#{suffix}"
      end

      # Returns display name for method (handles initialize -> .new)
      def method_display_name(meth)
        return "#{meth[:class_name]}.new" if meth[:name] == :initialize
        return "#{meth[:class_name]}.#{meth[:name]}" if meth[:scope] == :class

        meth[:name].to_s
      end

      # Unified signature: params with types, then return type
      def render_unified_signature(meth)
        lines = render_params_with_types(meth[:params])
        lines << render_return_line(meth)
        lines.compact.reject(&:empty?).join("\n")
      end

      # Params as aligned: ⟨name : Type = default⟩ → description
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

      # Convert YARD-style generics to RBS-style (`Array<X>` → `Array[X]`)
      def normalize_type(type)
        type.tr("<", "[").tr(">", "]")
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

      # Return type line: → ReturnType
      def render_return_line(meth)
        type = resolve_return_type(meth)
        return nil unless type

        type = normalize_type(type)
        desc = meth[:returns][:text].to_s
        desc.empty? ? "→ #{type}" : "→ #{type} — #{desc}"
      end

      def resolve_return_type(meth)
        returns = meth[:returns]
        return nil unless returns

        type = returns[:types]&.first
        type = meth[:class_name] if meth[:name] == :initialize && type == "void"
        type unless type.nil? || type == "void"
      end

      # Filter out useless auto-generated docstrings.
      def useful_docstring?(docstring)
        return false if docstring.to_s.empty?
        return false if docstring.match?(/\AReturns the value of attribute \w+\.?\z/)

        true
      end

      def linkify_docstring(docstring, context)
        return docstring unless @class_linker

        @class_linker.linkify_docstring(docstring, context: context)
      end

      def render_examples(examples)
        return [] if examples.nil? || examples.empty?

        examples.flat_map do |ex|
          label = ex[:name] ? "Example: #{ex[:name]}" : "Example"
          ["**#{label}:**", "```ruby\n#{ex[:text]}\n```"]
        end
      end

      def render_behaviors(behaviors)
        return [] if !@include_specs || behaviors.nil? || behaviors.empty?

        items = behaviors.first(8).map { |b| "- #{b}" }.join("\n")
        ["**Tested behaviors:**\n#{items}"]
      end

      def render_method_specs(examples)
        return [] if !@include_specs || examples.nil? || examples.empty?

        examples.first(3).flat_map { |e| ["**From specs (#{e[:name]}):**", "```ruby\n#{e[:code]}\n```"] }
      end
    end
  end
end
