# frozen_string_literal: true

require "fileutils"

module Chiridion
  # Documentation engine for generating agent-oriented docs from Ruby source.
  #
  # Coordinates several specialized components:
  # - {Extractor} - Walks YARD registry, extracts class/method/constant metadata
  # - {RbsLoader} - Loads RBS type signatures from sig/ directory
  # - {SpecExampleLoader} - Extracts usage examples from RSpec files
  # - {TypeMerger} - Merges RBS types with YARD documentation
  # - {Renderer} - Generates markdown with Obsidian-compatible wikilinks
  # - {Writer} - Handles file I/O with content-based change detection
  # - {DriftChecker} - Detects when docs are out of sync with source
  #
  # ## YARD Registry Persistence
  #
  # For performance, the engine persists YARD's parsed registry to .yardoc/.
  # This enables efficient partial refreshes: when a single file changes, we
  # load the existing registry, re-parse only that file, and regenerate only
  # the affected documentation.
  #
  # @example Generate docs via Engine
  #   engine = Chiridion::Engine.new(
  #     paths: ['lib/myproject'],
  #     output: 'docs/sys',
  #     namespace_filter: 'MyProject::'
  #   )
  #   engine.refresh
  #
  # @example Partial refresh (single file)
  #   engine = Chiridion::Engine.new(
  #     paths: ['lib/myproject/config.rb'],
  #     output: 'docs/sys',
  #     namespace_filter: 'MyProject::'
  #   )
  #   engine.refresh
  #
  class Engine
    # @return [Array<String>] Source paths being documented
    attr_reader :paths

    # @return [String] Output directory for generated docs
    attr_reader :output

    # Create a new documentation engine.
    #
    # @param paths [Array<String>] Source files or directories to document.
    #   Can be specific files for partial refresh or directories for full refresh.
    # @param output [String] Output directory for generated markdown docs.
    # @param namespace_filter [String, nil] Only document classes starting with this prefix.
    # @param namespace_strip [String, nil] Strip this prefix from output paths (defaults to namespace_filter).
    # @param include_specs [Boolean] Whether to extract usage examples from spec files.
    # @param verbose [Boolean] Whether to show detailed progress and warnings.
    # @param logger [#info, #warn, nil] Logger for output messages.
    # @param root [String] Project root directory for resolving relative paths.
    # @param rbs_path [String] Path to RBS signatures directory.
    # @param spec_path [String] Path to spec directory.
    # @param github_repo [String, nil] GitHub repository for source links.
    # @param github_branch [String] Git branch for source links.
    def initialize(
      paths:,
      output:,
      namespace_filter: nil,
      namespace_strip: nil,
      include_specs: false,
      verbose: false,
      logger: nil,
      root: Dir.pwd,
      rbs_path: "sig",
      spec_path: "spec",
      github_repo: nil,
      github_branch: "main"
    )
      @paths = Array(paths)
      @output = output
      @namespace_filter = namespace_filter
      @namespace_strip = namespace_strip || namespace_filter
      @include_specs = include_specs
      @verbose = verbose
      @logger = logger || DefaultLogger.new
      @root = root
      @rbs_path = rbs_path
      @spec_path = spec_path
      @github_repo = github_repo
      @github_branch = github_branch
    end

    # Generate documentation from source and write to output directory.
    #
    # This is the main entry point for documentation generation. It:
    # 1. Parses Ruby source files with YARD
    # 2. Loads RBS type signatures
    # 3. Extracts spec examples (if enabled)
    # 4. Merges types with YARD docs
    # 5. Renders to markdown with wikilinks
    # 6. Writes files with content-based change detection
    #
    # @return [void]
    def refresh
      require "yard"

      @logger.info "Parsing Ruby files in #{paths_description}..."

      load_sources
      doc_structure = extract_documentation(YARD::Registry)
      write_documentation(doc_structure)
      @logger.info "Documentation written to #{@output}/"
    end

    # Check for documentation drift without writing files.
    #
    # Compares what would be generated against existing docs. Useful in CI
    # to ensure docs are kept in sync with source code changes.
    #
    # @return [void]
    # @raise [SystemExit] Exits with code 1 if drift is detected
    def check
      require "yard"

      @logger.info "Checking documentation drift for #{paths_description}..."

      load_sources
      doc_structure = extract_documentation(YARD::Registry)
      check_for_drift(doc_structure)
    end

    private

    def paths_description
      @paths.size == 1 ? @paths.first : "#{@paths.size} paths"
    end

    def load_sources
      # Suppress YARD's verbose proxy warnings unless in verbose mode
      original_log_level = YARD::Logger.instance.level
      YARD::Logger.instance.level = @verbose ? Logger::WARN : Logger::ERROR

      @source_files = @paths.flat_map { |p| resolve_ruby_files(p) }.map { |f| File.expand_path(f) }

      if partial_refresh?
        load_or_create_registry
      else
        YARD::Registry.clear
      end
      YARD.parse(@source_files)
      YARD::Registry.save(true)

      YARD::Logger.instance.level = original_log_level

      # Load RBS types: inline annotations take precedence over sig/ files
      inline_types = InlineRbsLoader.new(@verbose, @logger).load(@source_files)
      sig_types = RbsLoader.new(@rbs_path, @verbose, @logger).load
      @rbs_types = merge_rbs_types(sig_types, inline_types)

      @spec_examples = @include_specs ? SpecExampleLoader.new(@spec_path, @verbose, @logger).load : {}
    end

    def partial_refresh?
      @paths.all? { |p| File.file?(p) }
    end

    def load_or_create_registry
      yardoc_path = File.join(@root, ".yardoc")
      if File.exist?(yardoc_path)
        YARD::Registry.load(yardoc_path)
      else
        YARD::Registry.clear
      end
    end

    def resolve_ruby_files(path)
      if File.directory?(path)
        Dir.glob("#{path}/**/*.rb")
      elsif File.file?(path) && path.end_with?(".rb")
        [path]
      else
        @logger.warn "Skipping invalid path: #{path}"
        []
      end
    end

    def extract_documentation(registry)
      source_filter = partial_refresh? ? @source_files : nil
      Extractor.new(
        @rbs_types,
        @spec_examples,
        @namespace_filter,
        @logger
      ).extract(registry, source_filter: source_filter)
    end

    def write_documentation(structure)
      Writer.new(
        @output,
        @namespace_strip,
        @include_specs,
        @verbose,
        @logger,
        github_repo: @github_repo,
        github_branch: @github_branch
      ).write(structure)
    end

    def check_for_drift(structure)
      DriftChecker.new(
        @output,
        @namespace_strip,
        @include_specs,
        @verbose,
        @logger
      ).check(structure)
    end

    # Merge RBS types from sig/ files and inline annotations.
    # Inline types take precedence over sig/ file types.
    def merge_rbs_types(sig_types, inline_types)
      merged = sig_types.dup

      inline_types.each do |class_name, methods|
        merged[class_name] ||= {}
        methods.each do |method_name, sig|
          merged[class_name][method_name] = sig
        end
      end

      merged
    end
  end

  # Simple default logger that prints to stderr.
  class DefaultLogger
    def info(msg) = $stderr.puts(msg)
    def warn(msg) = $stderr.puts("WARNING: #{msg}")
    def error(msg) = $stderr.puts("ERROR: #{msg}")
  end
end

# Load engine subcomponents
require_relative "engine/extractor"
require_relative "engine/rbs_loader"
require_relative "engine/inline_rbs_loader"
require_relative "engine/spec_example_loader"
require_relative "engine/type_merger"
require_relative "engine/renderer"
require_relative "engine/writer"
require_relative "engine/drift_checker"
