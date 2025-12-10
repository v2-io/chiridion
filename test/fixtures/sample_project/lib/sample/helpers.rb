# frozen_string_literal: true

module Sample
  # Utility methods for string formatting.
  #
  # Include this module to gain access to formatting helpers.
  #
  # @see Sample::Calculator
  module Helpers
    # Format a number with the given precision.
    #
    # @rbs value: Numeric
    # @rbs precision: Integer
    # @rbs return: String
    def format_number(value, precision = 2) = format("%.#{precision}f", value)

    # Titlecase a string.
    #
    # @param str [String] input string
    # @return [String] titlecased string
    def titlecase(str) = str.split.map(&:capitalize).join(" ")
  end
end
