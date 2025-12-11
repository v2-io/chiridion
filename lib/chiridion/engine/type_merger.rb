# frozen_string_literal: true

module Chiridion
  class Engine
    # Merges RBS type signatures with YARD documentation.
    #
    # RBS is treated as authoritative for types. When YARD and RBS disagree,
    # a warning is logged but RBS types are used. This ensures documentation
    # reflects the actual type contracts defined in sig/*.rbs.
    class TypeMerger
      # Known type equivalences between YARD conventions and RBS.
      BOOLEAN_TYPES    = %w[bool TrueClass FalseClass].freeze
      GENERIC_PREFIXES = { "Hash" => "Hash[", "Array" => "Array[" }.freeze

      def initialize(logger = nil) = @logger = logger

      # Merge YARD params with RBS types - RBS is authoritative.
      #
      # @param yard_params [Array<Hash>] Parameters from YARD
      # @param rbs_data [Hash, nil] RBS signature data
      # @param class_path [String] Class path for warnings
      # @param method_name [Symbol] Method name for warnings
      # @return [Array<Hash>] Merged parameters
      def merge_params(yard_params, rbs_data, class_path, method_name)
        return yard_params unless rbs_data&.dig(:params)

        rbs_params = rbs_data[:params]
        yard_params.map { |p| merge_single_param(p, rbs_params, class_path, method_name) }
      end

      # Merge YARD return with RBS return type - RBS is authoritative.
      #
      # @param yard_return [Hash, nil] Return info from YARD
      # @param rbs_data [Hash, nil] RBS signature data
      # @param class_path [String] Class path for warnings
      # @param method_name [Symbol] Method name for warnings
      # @return [Hash, nil] Merged return info
      def merge_return(yard_return, rbs_data, class_path, method_name)
        return yard_return unless rbs_data&.dig(:returns)

        rbs_return_data = rbs_data[:returns]

        # Handle both old format (string) and new format ({ type:, desc: })
        rbs_type = rbs_return_data.is_a?(Hash) ? rbs_return_data[:type] : rbs_return_data
        rbs_desc = rbs_return_data.is_a?(Hash) ? rbs_return_data[:desc] : nil

        if yard_return
          check_return_mismatch(yard_return, rbs_type, class_path, method_name)
          merged_desc = merge_description(yard_return[:text], rbs_desc)
          yard_return.merge(types: [rbs_type], text: merged_desc)
        else
          { types: [rbs_type], text: rbs_desc }
        end
      end

      private

      def merge_single_param(param, rbs_params, class_path, method_name)
        param_name = clean_param_name(param[:name])
        rbs_data   = rbs_params[param_name]
        return param unless rbs_data

        # Handle both old format (string) and new format ({ type:, desc: })
        rbs_type = rbs_data.is_a?(Hash) ? rbs_data[:type] : rbs_data
        rbs_desc = rbs_data.is_a?(Hash) ? rbs_data[:desc] : nil

        check_param_mismatch(param, rbs_type, class_path, method_name, param_name)

        merged_desc = merge_description(param[:text], rbs_desc)
        param.merge(types: [rbs_type], text: merged_desc)
      end

      # Merge descriptions - longer one wins, tie goes to RBS (co-located).
      def merge_description(yard_desc, rbs_desc)
        return rbs_desc if yard_desc.to_s.strip.empty?
        return yard_desc if rbs_desc.to_s.strip.empty?

        rbs_desc.to_s.length >= yard_desc.to_s.length ? rbs_desc : yard_desc
      end

      def clean_param_name(name) = name.to_s.gsub(/\A[*&]+/, "").delete_suffix(":")

      def check_param_mismatch(param, rbs_type, class_path, method_name, param_name)
        yard_type = param[:types]&.join(", ")
        return if yard_type.nil? || types_compatible?(yard_type, rbs_type)

        warn_mismatch(class_path, method_name, param_name, yard_type, rbs_type)
      end

      def check_return_mismatch(yard_return, rbs_return, class_path, method_name)
        yard_type = yard_return[:types]&.join(", ")
        return if yard_type.nil? || types_compatible?(yard_type, rbs_return)

        warn_mismatch(class_path, method_name, "(return)", yard_type, rbs_return)
      end

      # Check if YARD and RBS types are compatible (loose comparison).
      def types_compatible?(yard_type, rbs_type)
        return true if yard_type.nil? || rbs_type.nil?

        yard_norm = normalize_type(yard_type)
        rbs_norm  = normalize_type(rbs_type)

        exact_or_prefix_match?(yard_norm, rbs_norm) || equivalent_types?(yard_norm, rbs_norm)
      end

      def exact_or_prefix_match?(yard_norm, rbs_norm) = yard_norm == rbs_norm || rbs_norm.start_with?(yard_norm)

      def equivalent_types?(yard_norm, rbs_norm)
        return true if yard_norm == "Boolean" && BOOLEAN_TYPES.include?(rbs_norm)

        prefix = GENERIC_PREFIXES[yard_norm]
        prefix && rbs_norm.start_with?(prefix)
      end

      def normalize_type(type) = type.to_s.gsub(/\s+/, "").tr("<", "[").tr(">", "]")

      def warn_mismatch(class_path, method_name, param_name, yard_type, rbs_type)
        return unless @logger

        @logger.warn "Type mismatch in #{class_path}##{method_name} param '#{param_name}': " \
                     "YARD says '#{yard_type}', RBS says '#{rbs_type}' (using RBS)"
      end
    end
  end
end
