# frozen_string_literal: true

module Chiridion
  class Engine
    # Loads RBS type signatures from sig/ directory for documentation enrichment.
    #
    # Parses RBS files and extracts method signatures to merge with YARD documentation,
    # providing accurate type information in generated docs.
    class RbsLoader
      def initialize(rbs_path, verbose, logger)
        @rbs_path = rbs_path
        @verbose  = verbose
        @logger   = logger
      end

      # Load all RBS files and return a hash of class -> method -> signature.
      #
      # @return [Hash{String => Hash{String => Hash}}] Nested hash of signatures
      def load
        signatures = {}
        rbs_files  = Dir.glob("#{@rbs_path}/**/*.rbs")

        return signatures if rbs_files.empty?

        @logger.info "Loading #{rbs_files.size} RBS files..." if @verbose
        rbs_files.each { |file| parse_file(file, signatures) }
        signatures
      end

      private

      def parse_file(file, signatures)
        content       = File.read(file)
        current_class = nil

        content.each_line do |line|
          current_class = extract_class_name(line, signatures, current_class)
          next unless current_class

          extract_method_signature(line, signatures, current_class)
          extract_attr_signature(line, signatures, current_class)
        end
      end

      def extract_class_name(line, signatures, current_class)
        return current_class unless line =~ /^\s*(?:class|module)\s+([\w:]+)/

        class_name               = Regexp.last_match(1)
        signatures[class_name] ||= {}
        class_name
      end

      def extract_method_signature(line, signatures, current_class)
        return unless line =~ /^\s*def\s+(?:self\.)?(\w+[?!]?):\s*(.+)$/

        method_name                            = Regexp.last_match(1)
        full_sig                               = Regexp.last_match(2).strip
        signatures[current_class][method_name] = parse_signature(full_sig)
      end

      def extract_attr_signature(line, signatures, current_class)
        return unless line =~ /^\s*attr_(?:reader|accessor)\s+(\w+):\s*(.+)$/

        attr_name                            = Regexp.last_match(1)
        attr_type                            = Regexp.last_match(2).strip
        signatures[current_class][attr_name] = {
          full:    "() -> #{attr_type}",
          params:  {},
          returns: attr_type
        }
      end

      # Parse RBS signature into structured data.
      #
      # @param sig [String] RBS signature string
      # @return [Hash] Parsed signature with :full, :params, :returns keys
      def parse_signature(sig)
        result = { full: sig, params: {}, returns: nil }

        if sig =~ /\A\(([^)]*)\)\s*->\s*(.+)\z/
          params_str       = Regexp.last_match(1)
          result[:returns] = Regexp.last_match(2).strip
          parse_params(params_str, result[:params])
        elsif sig =~ /\A\(\)\s*->\s*(.+)\z/
          result[:returns] = Regexp.last_match(1).strip
        end

        result
      end

      # Parse RBS parameter list, handling nested brackets.
      def parse_params(params_str, result)
        return if params_str.strip.empty?

        params = split_respecting_brackets(params_str)

        params.each do |param|
          param = param.strip
          next if param.empty?

          parse_single_param(param, result)
        end
      end

      def parse_single_param(param, result)
        # Keyword arg: `?name: Type?` or `name: Type`
        if param =~ /\A\??(\w+):\s*(.+)\z/
          name         = Regexp.last_match(1)
          type         = Regexp.last_match(2).strip.delete_suffix("?")
          result[name] = type
        # Positional: `?Type name` or `Type name`
        elsif param =~ /\A\??(.+?)\s+(\w+)\z/
          type         = Regexp.last_match(1).strip
          name         = Regexp.last_match(2)
          result[name] = type
        end
      end

      # Split string by commas while respecting nested brackets [], {}, ().
      def split_respecting_brackets(str)
        result  = []
        current = +""  # Mutable string
        depth   = 0

        str.each_char do |c|
          case c
          when "[", "{", "("
            depth += 1
            current << c
          when "]", "}", ")"
            depth -= 1
            current << c
          when ","
            if depth.zero?
              result << current
              current = +""  # Mutable string
            else
              current << c
            end
          else
            current << c
          end
        end

        result << current unless current.empty?
        result
      end
    end
  end
end
