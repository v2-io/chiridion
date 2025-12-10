# frozen_string_literal: true

tool "test" do
  desc "Run Minitest tests"
  remaining_args :files, desc: "Specific test files to run (default: all)"

  def run
    if files.empty?
      exec("bundle", "exec", "ruby", "-Itest", "-e",
           "Dir.glob('test/**/*_test.rb').each { |f| require File.expand_path(f) }")
    else
      files.each do |file|
        exec("bundle", "exec", "ruby", "-Itest", file)
      end
    end
  end
end

tool "cop" do
  desc "Run RuboCop linter"
  flag :fix, "-a", "--fix", desc: "Auto-fix correctable offenses"
  flag :unsafe, "-A", "--unsafe", desc: "Auto-fix including unsafe corrections"

  def run
    args = %w[bundle exec rubocop]
    args << "-a" if fix && !unsafe
    args << "-A" if unsafe
    exec(*args)
  end
end

tool "gem" do
  desc "Gem packaging tasks"

  tool "build" do
    desc "Build the gem"

    def run
      require_relative "lib/chiridion/version"

      # Clean old gems
      Dir.glob("chiridion-*.gem").each { |f| File.delete(f) }

      exec("gem", "build", "chiridion.gemspec")
    end
  end

  tool "install" do
    desc "Build and install the gem locally"

    def run
      require_relative "lib/chiridion/version"

      # Clean and build
      Dir.glob("chiridion-*.gem").each { |f| File.delete(f) }
      system("gem", "build", "chiridion.gemspec") || exit(1)

      # Install
      gem_file = "chiridion-#{Chiridion::VERSION}.gem"
      exec("gem", "install", gem_file)
    end
  end
end

tool "docs" do
  desc "Documentation generation tasks"

  tool "refresh" do
    desc "Regenerate API documentation in docs/sys/"
    flag :verbose, "-v", desc: "Show verbose output"

    def run
      require "logger"
      require_relative "lib/chiridion"

      Chiridion.configure do |c|
        c.source_path      = "lib/chiridion"
        c.output           = "docs/sys"
        c.namespace_filter = "Chiridion::"
        c.github_repo      = "v2-io/chiridion"
        c.verbose          = verbose
      end
      Chiridion.refresh
    end
  end

  tool "check" do
    desc "Check for documentation drift (CI mode)"

    def run
      require "logger"
      require_relative "lib/chiridion"

      Chiridion.configure do |c|
        c.source_path      = "lib/chiridion"
        c.output           = "docs/sys"
        c.namespace_filter = "Chiridion::"
        c.github_repo      = "v2-io/chiridion"
      end
      Chiridion.check
    end
  end
end
