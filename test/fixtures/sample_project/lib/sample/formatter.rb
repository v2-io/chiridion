# frozen_string_literal: true

module Sample
  # Formats text output for display.
  #
  # This class demonstrates pure YARD documentation without any @rbs
  # annotations. Chiridion should handle this gracefully, using YARD
  # types when RBS types are not available.
  #
  # @example Basic usage
  #   formatter = Formatter.new
  #   formatter.wrap("Hello world", 5)  #=> "Hello\nworld"
  #
  # @see Sample::Calculator
  class Formatter
    # Default line width for wrapping.
    DEFAULT_WIDTH = 80

    # @return [String] the separator used between lines
    attr_reader :separator

    # Creates a new formatter.
    #
    # @param separator [String] line separator (default: newline)
    def initialize(separator = "\n") = @separator = separator

    # Wraps text to fit within a maximum width.
    #
    # @param text [String] the text to wrap
    # @param width [Integer] maximum line width
    # @return [String] wrapped text with lines separated by separator
    def wrap(text, width = DEFAULT_WIDTH)
      return text if text.length <= width

      words        = text.split
      lines        = []
      current_line = []

      words.each do |word|
        if (current_line + [word]).join(" ").length <= width
          current_line << word
        else
          lines << current_line.join(" ") unless current_line.empty?
          current_line = [word]
        end
      end
      lines << current_line.join(" ") unless current_line.empty?

      lines.join(@separator)
    end

    # Truncates text to a maximum length.
    #
    # @param text [String] the text to truncate
    # @param max_length [Integer] maximum length including suffix
    # @param suffix [String] suffix to append when truncated
    # @return [String] truncated text
    def truncate(text, max_length, suffix = "...")
      return text if text.length <= max_length

      truncate_at = max_length - suffix.length
      "#{text[0, truncate_at]}#{suffix}"
    end

    # Centers text within a given width.
    #
    # @param text [String] the text to center
    # @param width [Integer] total width
    # @param padding [String] character to use for padding
    # @return [String] centered text
    def center(text, width, padding = " ") = text.center(width, padding)

    # Checks if text is blank (nil, empty, or whitespace only).
    #
    # @param text [String, nil] the text to check
    # @return [Boolean] true if blank
    def self.blank?(text)
      text.nil? || text.strip.empty?
    end
  end
end
