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
    # @param project_title [String] Title for the documentation index.
    # @param index_description [String, nil] Custom description for the index page.
    # @param inline_source_threshold [Integer, nil] Max body lines for inline source display.
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
      spec_path: "test",
      github_repo: nil,
      github_branch: "main",
      project_title: "API Documentation",
      index_description: nil,
      inline_source_threshold: 10
    )
      @paths                   = Array(paths)
      @output                  = output
      @namespace_filter        = namespace_filter
      @namespace_strip         = namespace_strip || namespace_filter
      @include_specs           = include_specs
      @verbose                 = verbose
      @logger                  = logger || DefaultLogger.new
      @root                    = root
      @rbs_path                = rbs_path
      @spec_path               = spec_path
      @github_repo             = github_repo
      @github_branch           = github_branch
      @project_title           = project_title
      @index_description       = index_description
      @inline_source_threshold = inline_source_threshold
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
      register_rbs_tag

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
      register_rbs_tag

      @logger.info "Checking documentation drift for #{paths_description}..."

      load_sources
      doc_structure = extract_documentation(YARD::Registry)
      check_for_drift(doc_structure)
    end

    private

    def paths_description = @paths.size == 1 ? @paths.first : "#{@paths.size} paths"

    # Register @rbs as a known YARD tag to suppress "Unknown tag" warnings
    def register_rbs_tag
      return if YARD::Tags::Library.labels.key?(:rbs)

      YARD::Tags::Library.define_tag("RBS type annotation", :rbs, :with_types_and_name)
    end

    def load_sources
      # Suppress YARD's verbose proxy warnings unless in verbose mode
      original_log_level          = YARD::Logger.instance.level
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
      inline_types, @rbs_file_namespaces = InlineRbsLoader.new(@verbose, @logger).load(@source_files)
      sig_types                          = RbsLoader.new(@rbs_path, @verbose, @logger).load
      @rbs_types                         = merge_rbs_types(sig_types, inline_types)

      # Load type aliases from generated RBS files (sig/generated/ is standard for RBS::Inline)
      rbs_generated_dir = find_rbs_generated_dir
      @type_aliases     = RbsTypeAliasLoader.new(@verbose, @logger, rbs_dir: rbs_generated_dir).load

      @spec_examples = @include_specs ? SpecExampleLoader.new(@spec_path, @verbose, @logger).load : {}
    end

    def partial_refresh? = @paths.all? { |p| File.file?(p) }

    def load_or_create_registry
      yardoc_path = File.join(@root, ".yardoc")
      if File.exist?(yardoc_path)
        YARD::Registry.load(yardoc_path)
      else
        YARD::Registry.clear
      end
    end

    # Locate directory containing generated RBS files.
    #
    # RBS::Inline outputs to sig/generated/ by convention. Falls back to
    # sig/ if generated/ doesn't exist, or nil if no RBS directory exists.
    def find_rbs_generated_dir
      generated_dir = File.join(@root, @rbs_path, "generated")
      return generated_dir if Dir.exist?(generated_dir)

      sig_dir = File.join(@root, @rbs_path)
      return sig_dir if Dir.exist?(sig_dir)

      nil
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
      structure     = Extractor.new(
        @rbs_types,
        @spec_examples,
        @namespace_filter,
        @logger,
        rbs_file_namespaces: @rbs_file_namespaces,
        type_aliases:        @type_aliases
      ).extract(registry, source_filter: source_filter)

      # Add type aliases to the structure (for standalone reference page)
      structure[:type_aliases] = @type_aliases
      structure
    end

    def write_documentation(structure)
      Writer.new(
        @output,
        @namespace_strip,
        @include_specs,
        @verbose,
        @logger,
        root:                    @root,
        github_repo:             @github_repo,
        github_branch:           @github_branch,
        project_title:           @project_title,
        index_description:       @index_description,
        inline_source_threshold: @inline_source_threshold
      ).write(structure)
    end

    def check_for_drift(structure)
      DriftChecker.new(
        @output,
        @namespace_strip,
        @include_specs,
        @verbose,
        @logger,
        root:                    @root,
        github_repo:             @github_repo,
        github_branch:           @github_branch,
        project_title:           @project_title,
        inline_source_threshold: @inline_source_threshold
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
    def info(msg) = Kernel.warn(msg)
    def warn(msg) = Kernel.warn("WARNING: #{msg}")
    def error(msg) = Kernel.warn("ERROR: #{msg}")
  end
end

# Load engine subcomponents
require_relative "engine/extractor"
require_relative "engine/rbs_loader"
require_relative "engine/inline_rbs_loader"
require_relative "engine/rbs_type_alias_loader"
require_relative "engine/spec_example_loader"
require_relative "engine/type_merger"
require_relative "engine/class_linker"
require_relative "engine/github_linker"
require_relative "engine/frontmatter_builder"
require_relative "engine/template_renderer"
require_relative "engine/renderer"
require_relative "engine/writer"
require_relative "engine/drift_checker"
