# frozen_string_literal: true

module Sample
  # A simple calculator for testing documentation generation.
  #
  # This class demonstrates various YARD and RBS annotation patterns.
  #
  # @example Basic usage
  #   calc = Calculator.new
  #   calc.add(2, 3) # => 5
  class Calculator
    # The version of this calculator.
    VERSION = "1.0.0"

    # Default precision for floating point operations.
    DEFAULT_PRECISION = 2

    # @return [Integer] Running total of operations
    attr_reader :total

    # Create a new calculator.
    #
    # @param initial [Integer] Starting value
    def initialize(initial = 0) = @total = initial

    # Add two numbers.
    #
    # @rbs a: Integer -- first operand
    # @rbs b: Integer -- second operand
    # @rbs return: Integer
    def add(a, b) = a + b

    # Subtract b from a.
    #
    # @param a [Integer] minuend
    # @param b [Integer] subtrahend
    # @return [Integer] difference
    def subtract(a, b) = a - b

    # A method with a longer implementation that should NOT be inlined.
    #
    # @param numbers [Array<Integer>] numbers to process
    # @return [Hash] statistics about the numbers
    def compute_stats(numbers)
      return {} if numbers.empty?

      sum    = numbers.sum
      count  = numbers.size
      mean   = sum.to_f / count
      sorted = numbers.sort
      median = if count.odd?
                 sorted[count / 2]
               else
                 (sorted[(count / 2) - 1] + sorted[count / 2]) / 2.0
               end

      { sum: sum, count: count, mean: mean, median: median }
    end

    # Reset the calculator.
    def reset = @total = 0

    # Class method example.
    #
    # @param value [Numeric] value to check
    # @return [Boolean] true if positive
    def self.positive?(value)
      value.positive?
    end
  end
end
