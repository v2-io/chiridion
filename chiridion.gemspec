# frozen_string_literal: true

require_relative "lib/chiridion/version"

Gem::Specification.new do |spec|
  spec.name    = "chiridion"
  spec.version = Chiridion::VERSION
  spec.authors = ["Joseph Wecker"]
  spec.email   = ["joseph.wecker@gmail.com"]

  spec.summary               = "Agent-oriented documentation generator for Ruby projects"
  spec.description           = <<~DESC
    Chiridion generates documentation optimized for AI agents and LLMs working with
    Ruby codebases. It extracts documentation from YARD comments, merges RBS type
    signatures, and produces structured markdown suitable for context injection.

    Features:
    - YARD-based documentation extraction
    - RBS type signature integration (RBS is authoritative)
    - RSpec example extraction
    - Obsidian-compatible wikilinks for cross-references
    - Drift detection for CI/CD pipelines
    - toys/dx CLI task definitions
  DESC
  spec.homepage              = "https://github.com/v2-io/chiridion"
  spec.license               = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir.glob("{lib,sig,exe,templates}/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies (dev deps are in Gemfile)
  spec.add_dependency "liquid", "~> 5.5"
  spec.add_dependency "yard", "~> 0.9"

  # Ruby default-gem extractions chiridion needs at runtime. Without these,
  # chiridion fails to load under bundler on Ruby >= 3.4 (the restricted
  # load path no longer auto-provides them):
  #   • logger — required directly (lib/chiridion/engine.rb); also used to
  #     set YARD's log level. Extracted from default gems in Ruby 3.5/4.0.
  #   • base64 — required (bare `require "base64"`) by the `liquid`
  #     dependency, which does not declare it itself. Extracted in 3.4.
  # Unpinned: both are frozen, tiny stdlib-extraction shims.
  spec.add_dependency "logger"
  spec.add_dependency "base64"
end
