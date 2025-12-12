# frozen_string_literal: true

require "fileutils"
require "logger"

module Chiridion
  # Semantic documentation engine - outputs structured JSON data.
  #
  # This is an alternative to the regular Engine that focuses on semantic
  # extraction and outputs machine-readable JSON alongside markdown. It's
  # useful for:
  #
  # - Verifying what data is being captured
  # - Debugging the extraction pipeline
  # - Generating LLM-friendly documentation
  # - Separating extraction from presentation
  #
  # Usage:
  #   engine = Chiridion::SemanticEngine.new(
  #     paths: ['lib/myproject'],
  #     output: 'docs/sys',
  #     namespace_filter: 'MyProject::'
  #   )
  #   engine.refresh
  #
  class SemanticEngine
    attr_reader :paths, :output

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
      project_title: "API Documentation",
      project_description: nil
    )
      @paths               = Array(paths)
      @output              = output
      @namespace_filter    = namespace_filter
      @namespace_strip     = namespace_strip || namespace_filter
      @include_specs       = include_specs
      @verbose             = verbose
      @logger              = logger || DefaultLogger.new
      @root                = root
      @rbs_path            = rbs_path
      @spec_path           = spec_path
      @project_title       = project_title
      @project_description = project_description
    end

    def refresh
      require "yard"
      register_rbs_tag

      @logger.info "Semantic extraction from #{paths_description}..."

      # Load sources
      load_sources

      # Extract using SemanticExtractor
      project_doc = extract_documentation

      # Render to JSON+markdown
      files = render_documentation(project_doc)

      # Write files
      write_files(files)

      @logger.info "Semantic docs written to #{@output}/ (#{files.size} files)"
    end

    private

    def paths_description
      @paths.size == 1 ? @paths.first : "#{@paths.size} paths"
    end

    def register_rbs_tag
      return if YARD::Tags::Library.labels.key?(:rbs)

      YARD::Tags::Library.define_tag("RBS type annotation", :rbs, :with_types_and_name)
    end

    def load_sources
      YARD::Logger.instance.level = @verbose ? ::Logger::WARN : ::Logger::ERROR

      @source_files = @paths.flat_map { |p| resolve_ruby_files(p) }.map { |f| File.expand_path(f) }

      YARD::Registry.clear
      YARD.parse(@source_files)

      # Load from generated RBS (authoritative types)
      rbs_generated_dir = find_rbs_generated_dir
      if rbs_generated_dir
        @rbs_data = Engine::GeneratedRbsLoader.new(verbose: @verbose, logger: @logger).load(rbs_generated_dir)
        @logger.info "Loaded types from #{rbs_generated_dir}" if @verbose
      else
        @rbs_data = Engine::GeneratedRbsLoader::Result.new(
          signatures: {}, ivars: {}, attrs: {}, type_aliases: {}, overloads: {}
        )
      end

      # Load spec examples if enabled
      @spec_examples = @include_specs ? Engine::SpecExampleLoader.new(@spec_path, @verbose, @logger).load : {}
    end

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

    def extract_documentation
      extractor = Engine::SemanticExtractor.new(
        rbs_types:        @rbs_data.signatures,
        rbs_attr_types:   @rbs_data.attrs,
        rbs_ivar_types:   @rbs_data.ivars,
        type_aliases:     @rbs_data.type_aliases,
        spec_examples:    @spec_examples,
        namespace_filter: @namespace_filter,
        logger:           @logger
      )

      extractor.extract(
        YARD::Registry,
        title:       @project_title,
        description: @project_description
      )
    end

    def render_documentation(project_doc)
      renderer = Engine::SemanticRenderer.new(
        namespace_strip: @namespace_strip,
        project_title:   @project_title
      )

      renderer.render(project_doc)
    end

    def write_files(files)
      FileUtils.mkdir_p(@output)

      files.each do |filename, content|
        filepath = File.join(@output, filename)
        dir      = File.dirname(filepath)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)

        # Only write if content changed
        if File.exist?(filepath)
          existing = File.read(filepath)
          next if existing == content
        end

        File.write(filepath, content)
        @logger.info "  Wrote #{filename}" if @verbose
      end
    end
  end
end

# Load required components
require_relative "engine/document_model"
require_relative "engine/generated_rbs_loader"
require_relative "engine/semantic_extractor"
require_relative "engine/semantic_renderer"
require_relative "engine/type_merger"
require_relative "engine/spec_example_loader"
