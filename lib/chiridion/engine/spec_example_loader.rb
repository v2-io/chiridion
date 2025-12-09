# frozen_string_literal: true

module Chiridion
  class Engine
    # Extracts usage examples from RSpec files.
    #
    # Parses spec files to find `let` declarations, `subject` blocks, and
    # test descriptions that can serve as documentation examples.
    class SpecExampleLoader
      def initialize(spec_path, verbose, logger)
        @spec_path = spec_path
        @verbose = verbose
        @logger = logger
      end

      # Load spec examples for all spec files.
      #
      # @return [Hash{String => Hash}] Class path => { method_examples:, behaviors:, lets:, subjects: }
      def load
        examples = {}
        spec_files = Dir.glob("#{@spec_path}/**/*_spec.rb")

        return examples if spec_files.empty?

        @logger.info "Loading examples from #{spec_files.size} spec files..." if @verbose
        spec_files.each { |file| parse_file(file, examples) }
        examples
      end

      private

      def parse_file(file, examples)
        content = File.read(file)
        current_class = extract_described_class(content)
        return unless current_class

        examples[current_class] ||= {
          method_examples: Hash.new { |h, k| h[k] = [] },
          behaviors: Hash.new { |h, k| h[k] = [] },
          lets: [],
          subjects: []
        }

        extract_lets(content, examples[current_class])
        extract_subjects(content, examples[current_class])
        extract_behaviors(content, examples[current_class])
      end

      def extract_described_class(content)
        # Match: RSpec.describe ClassName or describe ClassName
        if content =~ /(?:RSpec\.)?describe\s+([A-Z][\w:]+)/
          Regexp.last_match(1)
        end
      end

      def extract_lets(content, data)
        # Match: let(:name) { ... } or let!(:name) { ... }
        content.scan(/let!?\(:(\w+)\)\s*\{([^}]+)\}/) do |name, code|
          data[:lets] << { name: name, code: code.strip }
        end
      end

      def extract_subjects(content, data)
        # Match: subject { ... } or subject(:name) { ... }
        content.scan(/subject(?:\(:(\w+)\))?\s*\{([^}]+)\}/) do |name, code|
          data[:subjects] << { name: name || "subject", code: code.strip }
        end
      end

      def extract_behaviors(content, data)
        # Match: describe "#method" do or describe ".method" do
        current_method = nil
        content.each_line do |line|
          if line =~ /describe\s+['"](#|\.)\w+['"]/
            current_method = line[/['"](#|\.)(\w+)['"]/, 0]&.tr("'\"", "")
          elsif line =~ /it\s+['"]([^'"]+)['"]/ && current_method
            behavior = Regexp.last_match(1)
            data[:behaviors][current_method] << behavior
          end
        end
      end
    end
  end
end
