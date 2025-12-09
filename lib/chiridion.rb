# frozen_string_literal: true

require_relative "chiridion/version"
require_relative "chiridion/config"
require_relative "chiridion/engine"

# Chiridion: Agent-oriented documentation generator for Ruby projects.
#
# Chiridion ("handbook" in Greek, from the same root as Enchiridion) generates
# documentation optimized for AI agents and LLMs working with Ruby codebases.
# It extracts documentation from YARD comments, merges RBS type signatures,
# and produces structured markdown suitable for context injection.
#
# ## Key Features
#
# - **YARD Integration**: Extracts docstrings, @param, @return, @example tags
# - **RBS Authority**: RBS type signatures are authoritative over YARD types
# - **Spec Examples**: Extracts usage examples from RSpec files
# - **Wikilinks**: Obsidian-compatible [[Class::Name]] cross-references
# - **Drift Detection**: CI mode to ensure docs stay in sync with code
#
# ## Design Philosophy
#
# Traditional documentation is written for human developers reading in browsers.
# Agent-oriented documentation is optimized for LLMs processing in context windows:
#
# - Structured frontmatter with navigation metadata
# - Explicit type information (not just prose descriptions)
# - Cross-reference links that can be followed programmatically
# - Compact but complete method signatures
#
# @example Basic usage
#   engine = Chiridion::Engine.new(
#     paths: ['lib/myproject'],
#     output: 'docs/sys',
#     namespace_filter: 'MyProject::'
#   )
#   engine.refresh
#
# @example Configuration block
#   Chiridion.configure do |config|
#     config.output = 'docs/sys'
#     config.namespace_filter = 'MyProject::'
#     config.github_repo = 'user/repo'
#     config.include_specs = true
#   end
#   Chiridion.refresh(['lib/myproject'])
#
module Chiridion
  class Error < StandardError; end

  class << self
    # @return [Config] Global configuration instance
    def config
      @config ||= Config.new
    end

    # Configure Chiridion with a block.
    #
    # @yield [Config] Configuration object
    # @return [Config] Configured instance
    def configure
      yield config
      config
    end

    # Reset configuration to defaults (useful for testing).
    def reset_config!
      @config = Config.new
    end

    # Convenience method to run documentation refresh.
    #
    # @param paths [Array<String>] Source paths to document
    # @param output [String, nil] Override output directory
    # @return [void]
    def refresh(paths = nil, output: nil)
      engine = Engine.new(
        paths: paths || [config.source_path],
        output: output || config.output,
        namespace_filter: config.namespace_filter,
        include_specs: config.include_specs,
        verbose: config.verbose,
        logger: config.logger
      )
      engine.refresh
    end

    # Convenience method to check for documentation drift.
    #
    # @param paths [Array<String>] Source paths to check
    # @return [void]
    # @raise [SystemExit] Exits with code 1 if drift detected
    def check(paths = nil)
      engine = Engine.new(
        paths: paths || [config.source_path],
        output: config.output,
        namespace_filter: config.namespace_filter,
        include_specs: config.include_specs,
        verbose: config.verbose,
        logger: config.logger
      )
      engine.check
    end
  end
end
