# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "logger"

class EngineTest < Minitest::Test
  FIXTURES_PATH = File.expand_path("fixtures/sample_project/lib", __dir__)

  # Silent logger for tests
  class NullLogger
    def info(_msg)  = nil
    def warn(_msg)  = nil
    def error(_msg) = nil
  end

  def setup
    @tmpdir = Dir.mktmpdir("chiridion_test")
    @output = File.join(@tmpdir, "docs")
    @logger = NullLogger.new
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    YARD::Registry.clear if defined?(YARD::Registry)
  end

  def create_engine(**)
    Chiridion::Engine.new(
      paths:            [FIXTURES_PATH],
      output:           @output,
      namespace_filter: "Sample::",
      logger:           @logger,
      **
    )
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Basic file creation tests
  # ─────────────────────────────────────────────────────────────────────────────

  def test_refresh_creates_output_directory
    create_engine.refresh
    assert Dir.exist?(@output), "Output directory should be created"
  end

  def test_refresh_creates_index_file
    create_engine.refresh
    assert_path_exists File.join(@output, "index.md"), "index.md should be created"
  end

  def test_refresh_creates_class_documentation
    create_engine.refresh
    assert_path_exists File.join(@output, "calculator.md"), "calculator.md should be created"
  end

  def test_refresh_creates_module_documentation
    create_engine.refresh
    assert_path_exists File.join(@output, "helpers.md"), "helpers.md should be created"
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Content structure tests
  # ─────────────────────────────────────────────────────────────────────────────

  def test_generated_docs_contain_frontmatter
    create_engine.refresh
    content = File.read(File.join(@output, "calculator.md"))

    assert_match(/^---/, content)
    assert_match(/^title:/, content)
    assert_match(/^type:/, content)
  end

  def test_generated_docs_contain_class_name
    create_engine.refresh
    content = File.read(File.join(@output, "calculator.md"))

    assert_match(/Sample::Calculator/, content)
  end

  def test_generated_docs_contain_methods
    create_engine.refresh
    content = File.read(File.join(@output, "calculator.md"))

    assert_match(/add/, content)
    assert_match(/subtract/, content)
  end

  def test_index_lists_classes
    create_engine.refresh
    content = File.read(File.join(@output, "index.md"))

    assert_match(/Calculator/, content)
  end

  def test_index_lists_modules
    create_engine.refresh
    content = File.read(File.join(@output, "index.md"))

    assert_match(/Helpers/, content)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Inline source tests
  # ─────────────────────────────────────────────────────────────────────────────

  def test_inline_source_included_for_short_methods
    create_engine(inline_source_threshold: 10).refresh
    content = File.read(File.join(@output, "calculator.md"))

    # Short method 'add' should have inline source with location comment
    assert_match(/```ruby\n# .+ : ~\d+\ndef add/, content)
  end

  def test_inline_source_excluded_for_long_methods
    create_engine(inline_source_threshold: 5).refresh
    content = File.read(File.join(@output, "calculator.md"))

    # compute_stats is long - should NOT have inline source with threshold 5
    refute_match(/```ruby\ndef compute_stats/, content)
  end

  def test_inline_source_disabled_when_threshold_zero
    create_engine(inline_source_threshold: 0).refresh
    content = File.read(File.join(@output, "calculator.md"))

    # No methods should have inline source
    refute_match(/```ruby\ndef add/, content)
    refute_match(/```ruby\ndef reset/, content)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # GitHub links tests
  # ─────────────────────────────────────────────────────────────────────────────

  def test_github_links_when_configured
    create_engine(github_repo: "user/repo").refresh
    content = File.read(File.join(@output, "calculator.md"))

    assert_match(%r{github\.com/user/repo}, content)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Smart write tests
  # ─────────────────────────────────────────────────────────────────────────────

  def test_smart_write_skips_unchanged_files
    create_engine.refresh

    calc_path    = File.join(@output, "calculator.md")
    mtime_before = File.mtime(calc_path)

    sleep 0.1 # Ensure mtime would differ if file were rewritten

    create_engine.refresh
    mtime_after = File.mtime(calc_path)

    assert_equal mtime_before, mtime_after, "File should not be rewritten when content unchanged"
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Pure YARD (no RBS) tests
  # ─────────────────────────────────────────────────────────────────────────────

  def test_yard_only_class_generates_documentation
    create_engine.refresh

    formatter_path = File.join(@output, "formatter.md")
    assert_path_exists formatter_path, "formatter.md should be created for YARD-only class"
  end

  def test_yard_only_class_contains_param_types
    create_engine.refresh
    content = File.read(File.join(@output, "formatter.md"))

    # YARD @param types should appear in output
    assert_match(/String/, content, "YARD String type should appear")
    assert_match(/Integer/, content, "YARD Integer type should appear")
  end

  def test_yard_only_class_contains_return_types
    create_engine.refresh
    content = File.read(File.join(@output, "formatter.md"))

    # Methods with @return should have return type documented
    # wrap returns String, truncate returns String, blank? returns Boolean
    assert_match(/String/, content)
    assert_match(/Boolean/, content)
  end

  def test_yard_only_class_contains_methods
    create_engine.refresh
    content = File.read(File.join(@output, "formatter.md"))

    assert_match(/wrap/, content, "wrap method should be documented")
    assert_match(/truncate/, content, "truncate method should be documented")
    assert_match(/center/, content, "center method should be documented")
  end

  def test_yard_only_class_contains_class_methods
    create_engine.refresh
    content = File.read(File.join(@output, "formatter.md"))

    assert_match(/blank\?/, content, "class method blank? should be documented")
  end

  def test_yard_only_class_contains_constants
    create_engine.refresh
    content = File.read(File.join(@output, "formatter.md"))

    assert_match(/DEFAULT_WIDTH/, content, "DEFAULT_WIDTH constant should be documented")
  end

  def test_yard_only_class_contains_attr_reader
    create_engine.refresh
    content = File.read(File.join(@output, "formatter.md"))

    assert_match(/separator/, content, "attr_reader separator should be documented")
  end

  def test_yard_only_class_inline_source_works
    create_engine(inline_source_threshold: 10).refresh
    content = File.read(File.join(@output, "formatter.md"))

    # Short methods like 'center' should have inline source with location comment
    assert_match(/```ruby\n# .+ : ~\d+\ndef center/, content, "Short YARD-only methods should have inline source")
  end

  def test_yard_only_class_see_tags_captured
    create_engine.refresh
    content = File.read(File.join(@output, "formatter.md"))

    # @see Sample::Calculator should create a reference
    assert_match(/Calculator/, content, "@see reference should be captured")
  end

  def test_index_includes_yard_only_class
    create_engine.refresh
    content = File.read(File.join(@output, "index.md"))

    assert_match(/Formatter/, content, "YARD-only Formatter class should appear in index")
  end
end
