# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "logger"

class EngineTest < Minitest::Test
  FIXTURES_PATH = File.expand_path("fixtures/sample_project/lib", __dir__)

  def setup
    @tmpdir = Dir.mktmpdir("chiridion_test")
    @output = File.join(@tmpdir, "docs")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    YARD::Registry.clear if defined?(YARD::Registry)
  end

  def test_refresh_creates_output_directory
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )
    engine.refresh

    assert Dir.exist?(@output), "Output directory should be created"
  end

  def test_refresh_creates_index_file
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )
    engine.refresh

    index_path = File.join(@output, "index.md")
    assert_path_exists index_path, "index.md should be created"
  end

  def test_refresh_creates_class_documentation
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )
    engine.refresh

    calculator_path = File.join(@output, "calculator.md")
    assert_path_exists calculator_path, "calculator.md should be created"
  end

  def test_refresh_creates_module_documentation
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )
    engine.refresh

    helpers_path = File.join(@output, "helpers.md")
    assert_path_exists helpers_path, "helpers.md should be created"
  end

  def test_generated_docs_contain_frontmatter
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )
    engine.refresh

    content = File.read(File.join(@output, "calculator.md"))

    assert_match(/^---/, content)
    assert_match(/^title:/, content)
    assert_match(/^type:/, content)
  end

  def test_generated_docs_contain_class_name
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )
    engine.refresh

    content = File.read(File.join(@output, "calculator.md"))

    assert_match(/Sample::Calculator/, content)
  end

  def test_generated_docs_contain_methods
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )
    engine.refresh

    content = File.read(File.join(@output, "calculator.md"))

    assert_match(/add/, content)
    assert_match(/subtract/, content)
  end

  def test_inline_source_included_for_short_methods
    engine = Chiridion::Engine.new(
      paths:                   [FIXTURES_PATH],
      output:                  @output,
      namespace_filter:        "Sample::",
      inline_source_threshold: 10
    )
    engine.refresh

    content = File.read(File.join(@output, "calculator.md"))

    # Short method 'add' should have inline source
    assert_match(/```ruby\ndef add/, content)
  end

  def test_inline_source_excluded_for_long_methods
    engine = Chiridion::Engine.new(
      paths:                   [FIXTURES_PATH],
      output:                  @output,
      namespace_filter:        "Sample::",
      inline_source_threshold: 5
    )
    engine.refresh

    content = File.read(File.join(@output, "calculator.md"))

    # compute_stats is long - should NOT have inline source with threshold 5
    # Look for the method header but no immediately following code block with its def
    refute_match(/```ruby\ndef compute_stats/, content)
  end

  def test_inline_source_disabled_when_threshold_zero
    engine = Chiridion::Engine.new(
      paths:                   [FIXTURES_PATH],
      output:                  @output,
      namespace_filter:        "Sample::",
      inline_source_threshold: 0
    )
    engine.refresh

    content = File.read(File.join(@output, "calculator.md"))

    # No methods should have inline source
    refute_match(/```ruby\ndef add/, content)
    refute_match(/```ruby\ndef reset/, content)
  end

  def test_index_lists_classes
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )
    engine.refresh

    content = File.read(File.join(@output, "index.md"))

    assert_match(/Calculator/, content)
  end

  def test_index_lists_modules
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )
    engine.refresh

    content = File.read(File.join(@output, "index.md"))

    assert_match(/Helpers/, content)
  end

  def test_github_links_when_configured
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::",
      github_repo:      "user/repo"
    )
    engine.refresh

    content = File.read(File.join(@output, "calculator.md"))

    assert_match(%r{github\.com/user/repo}, content)
  end

  def test_smart_write_skips_unchanged_files
    engine = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )

    # First run
    engine.refresh

    # Get modification time
    calc_path    = File.join(@output, "calculator.md")
    mtime_before = File.mtime(calc_path)

    # Small delay to ensure mtime would differ
    sleep 0.1

    # Second run with same content
    engine2 = Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::"
    )
    engine2.refresh

    mtime_after = File.mtime(calc_path)

    # File should not have been rewritten (mtime unchanged)
    assert_equal mtime_before, mtime_after, "File should not be rewritten when content unchanged"
  end
end
