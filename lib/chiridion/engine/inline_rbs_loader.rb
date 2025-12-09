# frozen_string_literal: true

module Chiridion
  class Engine
    # Extracts RBS type signatures from inline annotations in Ruby source.
    #
    # Supports the rbs-inline format where types are specified in comments:
    #
    #   # @rbs param: String -- description
    #   # @rbs return: Integer
    #   def method(param)
    #
    # This is the preferred way to specify types in source code, as it keeps
    # type information co-located with the code. The RbsLoader handles
    # separate sig/ files as a fallback.
    #
    # @see https://github.com/soutaro/rbs-inline
    class InlineRbsLoader
      def initialize(verbose, logger)
        @verbose = verbose
        @logger = logger
      end

      # Extract inline RBS annotations from Ruby source files.
      #
      # @param source_files [Array<String>] Paths to Ruby files
      # @return [Hash{String => Hash{String => Hash}}] class -> method -> signature
      def load(source_files)
        signatures = {}

        source_files.each do |file|
          next unless File.exist?(file)

          parse_file(file, signatures)
        end

        @logger.info "Extracted inline RBS from #{source_files.size} files" if @verbose && source_files.any?
        signatures
      end

      private

      def parse_file(file, signatures)
        content = File.read(file)
        current_class = nil
        pending_rbs = {}

        content.each_line.with_index do |line, idx|
          # Track class/module context
          if line =~ /^\s*(?:class|module)\s+([\w:]+)/
            current_class = Regexp.last_match(1)
            signatures[current_class] ||= {}
            pending_rbs = {}
          end

          # Collect @rbs annotations
          if line =~ /^\s*#\s*@rbs\s+(\w+):\s*(.+)$/
            key = Regexp.last_match(1)
            value = Regexp.last_match(2).strip
            # Handle "-- description" suffix
            type, _desc = value.split(" -- ", 2)
            pending_rbs[key] = type.strip
          end

          # When we hit a method definition, apply pending RBS
          if current_class && line =~ /^\s*def\s+(?:self\.)?(\w+[?!]?)/
            method_name = Regexp.last_match(1)
            if pending_rbs.any?
              signatures[current_class][method_name] = build_signature(pending_rbs)
              pending_rbs = {}
            end
          end

          # Reset pending RBS on blank lines or non-comment lines (but not on def lines)
          is_comment = line.strip.start_with?("#")
          is_def = line =~ /^\s*def\s/
          is_blank = line.strip.empty?

          if is_blank || (!is_comment && !is_def)
            pending_rbs = {} unless is_def
          end
        end
      end

      def build_signature(rbs_data)
        params = {}
        returns = rbs_data.delete("return")

        rbs_data.each do |name, type|
          params[name] = type
        end

        param_str = params.map { |name, type| "#{type} #{name}" }.join(", ")
        full = "(#{param_str}) -> #{returns || "void"}"

        {
          full: full,
          params: params,
          returns: returns
        }
      end
    end
  end
end
