# frozen_string_literal: true

module Chiridion
  class Engine
    # Renders constant documentation to markdown.
    #
    # Handles both simple constants (rendered in a table) and complex constants
    # (multi-line values rendered as separate subsections with code blocks).
    class ConstantRenderer
      # Render all constants for a class/module.
      #
      # @param constants [Array<Hash>] Constant data from Extractor
      # @return [String] Markdown documentation
      def render(constants)
        return "" if constants.empty?

        _simple, complex = partition_constants(constants)
        parts = ["## Constants"]
        parts << render_table(constants, complex)
        complex.each { |c| parts << render_complex(c) }
        parts.join("\n\n")
      end

      private

      def partition_constants(constants)
        constants.partition { |c| c[:value].to_s.count("\n") <= 1 }
      end

      def render_table(constants, complex)
        rows = constants.map { |c| render_table_row(c, complex) }
        "| Constant | Value | Description |\n|----------|-------|-------------|\n#{rows.join("\n")}"
      end

      def render_table_row(constant, complex)
        value = complex.include?(constant) ? "*(see below)*" : format_simple(constant[:value])
        docstring = constant[:docstring].to_s.gsub(/\s*\n\s*/, " ").strip
        "| `#{constant[:name]}` | #{value} | #{docstring} |"
      end

      # Format simple constant values (0-1 newlines) for table cells.
      def format_simple(value)
        return "`nil`" if value.nil?

        str = strip_freeze(value.to_s)
        escaped = str.count("\n") == 1 ? str.gsub("|", "\\|").gsub("\n", "<br />") : str.gsub("|", "\\|")
        "`#{escaped}`"
      end

      # Render a complex constant as its own subsection with code block.
      def render_complex(constant)
        parts = ["### #{constant[:name]}"]
        parts << constant[:docstring] unless constant[:docstring].to_s.empty?
        parts << "```ruby\n#{constant[:name]} = #{strip_freeze(constant[:value])}\n```"
        parts.join("\n\n")
      end

      # Remove .freeze from constant values - implementation detail, not documentation.
      def strip_freeze(str)
        str.delete_suffix(".freeze")
      end
    end
  end
end
