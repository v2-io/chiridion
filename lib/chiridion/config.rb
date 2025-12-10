# frozen_string_literal: true

module Chiridion
  # Configuration for documentation generation.
  #
  # Chiridion can be configured globally or per-engine instance.
  # All options have sensible defaults for common Ruby project layouts.
  #
  # @example Global configuration
  #   Chiridion.configure do |config|
  #     config.output = 'docs/sys'
  #     config.namespace_filter = 'MyProject::'
  #     config.github_repo = 'user/repo'
  #   end
  #
  # @example Per-project configuration file
  #   # .chiridion.yml
  #   output: docs/sys
  #   namespace_filter: MyProject::
  #   github_repo: user/repo
  #   include_specs: true
  #
  class Config
    # @return [String] Root directory of the project (defaults to current directory)
    attr_accessor :root

    # @return [String] Source directory to document (relative to root)
    attr_accessor :source_path

    # @return [String] Output directory for generated docs
    attr_accessor :output

    # @return [String, nil] Namespace prefix to filter (e.g., "MyProject::")
    #   Only classes/modules starting with this prefix are documented.
    #   If nil, all classes are included.
    attr_accessor :namespace_filter

    # @return [String, nil] Namespace prefix to strip from output paths
    #   Defaults to namespace_filter value.
    attr_writer :namespace_strip

    # @return [String, nil] GitHub repository for source links (e.g., "user/repo")
    attr_accessor :github_repo

    # @return [String] Git branch for source links
    attr_accessor :github_branch

    # @return [Boolean] Whether to extract examples from spec files
    attr_accessor :include_specs

    # @return [String] Path to test directory (relative to root)
    attr_accessor :spec_path

    # @return [String] Path to RBS signatures directory (relative to root)
    attr_accessor :rbs_path

    # @return [Boolean] Verbose output during generation
    attr_accessor :verbose

    # @return [#info, #warn, #error, nil] Logger for output messages
    attr_accessor :logger

    # @return [Integer, nil] Maximum body lines for inline source display.
    #   Methods with body <= this many lines show their implementation inline.
    #   Set to nil or 0 to disable inline source. Default: 10.
    attr_accessor :inline_source_threshold

    def initialize
      @root                    = Dir.pwd
      @source_path             = "lib"
      @output                  = "docs/sys"
      @namespace_filter        = nil
      @namespace_strip         = nil
      @github_repo             = nil
      @github_branch           = "main"
      @include_specs           = false
      @spec_path               = "test"
      @rbs_path                = "sig"
      @verbose                 = false
      @logger                  = nil
      @inline_source_threshold = 10
    end

    # Namespace prefix to strip from output paths.
    # Defaults to namespace_filter if not explicitly set.
    def namespace_strip = @namespace_strip || @namespace_filter

    # Load configuration from a YAML file.
    #
    # @param path [String] Path to YAML configuration file
    # @return [Config] self
    def load_file(path)
      return self unless File.exist?(path)

      require "yaml"
      data = YAML.safe_load_file(path, symbolize_names: true)
      load_hash(data)
    end

    # Load configuration from a hash.
    #
    # @param data [Hash] Configuration values
    # @return [Config] self
    def load_hash(data)
      data.each do |key, value|
        setter = :"#{key}="
        public_send(setter, value) if respond_to?(setter)
      end
      self
    end

    # @return [String] Full path to source directory
    def full_source_path = File.join(root, source_path)

    # @return [String] Full path to output directory
    def full_output_path = File.join(root, output)

    # @return [String] Full path to spec directory
    def full_spec_path = File.join(root, spec_path)

    # @return [String] Full path to RBS directory
    def full_rbs_path = File.join(root, rbs_path)
  end
end
