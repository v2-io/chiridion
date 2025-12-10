# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  def setup = @config = Chiridion::Config.new

  def test_default_source_path             = assert_equal "lib", @config.source_path
  def test_default_output                  = assert_equal "docs/sys", @config.output
  def test_default_spec_path               = assert_equal "test", @config.spec_path
  def test_default_rbs_path                = assert_equal "sig", @config.rbs_path
  def test_default_github_branch           = assert_equal "main", @config.github_branch
  def test_default_inline_source_threshold = assert_equal 10, @config.inline_source_threshold
  def test_default_namespace_filter_is_nil = assert_nil @config.namespace_filter
  def test_default_github_repo_is_nil      = assert_nil @config.github_repo
  def test_default_include_specs_is_false  = refute @config.include_specs
  def test_default_verbose_is_false        = refute @config.verbose

  def test_namespace_strip_defaults_to_namespace_filter
    @config.namespace_filter = "MyProject::"
    assert_equal "MyProject::", @config.namespace_strip
  end

  def test_namespace_strip_can_be_set_independently
    @config.namespace_filter = "MyProject::"
    @config.namespace_strip  = "My::"
    assert_equal "My::", @config.namespace_strip
  end

  def test_load_hash
    @config.load_hash(
      source_path:             "src",
      output:                  "api_docs",
      namespace_filter:        "Foo::",
      inline_source_threshold: 5
    )

    assert_equal "src", @config.source_path
    assert_equal "api_docs", @config.output
    assert_equal "Foo::", @config.namespace_filter
    assert_equal 5, @config.inline_source_threshold
  end

  def test_load_hash_ignores_unknown_keys
    # Should not raise
    @config.load_hash(unknown_key: "value", another: 123)
    assert_equal "lib", @config.source_path # unchanged
  end

  def test_full_paths
    @config.root        = "/project"
    @config.source_path = "lib"
    @config.output      = "docs"
    @config.spec_path   = "test"
    @config.rbs_path    = "sig"

    assert_equal "/project/lib", @config.full_source_path
    assert_equal "/project/docs", @config.full_output_path
    assert_equal "/project/test", @config.full_spec_path
    assert_equal "/project/sig", @config.full_rbs_path
  end
end
