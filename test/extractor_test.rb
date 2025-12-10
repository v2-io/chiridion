# frozen_string_literal: true

require "test_helper"
require "yard"

class ExtractorTest < Minitest::Test
  FIXTURES_PATH = File.expand_path("fixtures/sample_project/lib", __dir__)

  def setup
    YARD::Registry.clear
    YARD.parse(Dir.glob("#{FIXTURES_PATH}/**/*.rb"))
  end

  def teardown = YARD::Registry.clear

  def test_extracts_classes_and_modules
    extractor = Chiridion::Engine::Extractor.new({}, {}, "Sample::", nil)
    structure = extractor.extract(YARD::Registry)

    class_paths  = structure[:classes].map { |c| c[:path] }
    module_paths = structure[:modules].map { |m| m[:path] }

    assert_includes class_paths, "Sample::Calculator"
    assert_includes module_paths, "Sample::Helpers"
  end

  def test_extracts_class_docstring
    extractor = Chiridion::Engine::Extractor.new({}, {}, "Sample::", nil)
    structure = extractor.extract(YARD::Registry)

    calculator = structure[:classes].find { |c| c[:path] == "Sample::Calculator" }

    assert_match(/simple calculator/i, calculator[:docstring])
  end

  def test_extracts_methods
    extractor = Chiridion::Engine::Extractor.new({}, {}, "Sample::", nil)
    structure = extractor.extract(YARD::Registry)

    calculator   = structure[:classes].find { |c| c[:path] == "Sample::Calculator" }
    method_names = calculator[:methods].map { |m| m[:name] }

    assert_includes method_names, :add
    assert_includes method_names, :subtract
    assert_includes method_names, :reset
    assert_includes method_names, :initialize
  end

  def test_extracts_class_methods
    extractor = Chiridion::Engine::Extractor.new({}, {}, "Sample::", nil)
    structure = extractor.extract(YARD::Registry)

    calculator         = structure[:classes].find { |c| c[:path] == "Sample::Calculator" }
    class_methods      = calculator[:methods].select { |m| m[:scope] == :class }
    class_method_names = class_methods.map { |m| m[:name] }

    assert_includes class_method_names, :positive?
  end

  def test_extracts_constants
    extractor = Chiridion::Engine::Extractor.new({}, {}, "Sample::", nil)
    structure = extractor.extract(YARD::Registry)

    calculator     = structure[:classes].find { |c| c[:path] == "Sample::Calculator" }
    constant_names = calculator[:constants].map { |c| c[:name] }

    assert_includes constant_names, :VERSION
    assert_includes constant_names, :DEFAULT_PRECISION
  end

  def test_extracts_method_params_from_yard
    extractor = Chiridion::Engine::Extractor.new({}, {}, "Sample::", nil)
    structure = extractor.extract(YARD::Registry)

    calculator = structure[:classes].find { |c| c[:path] == "Sample::Calculator" }
    subtract   = calculator[:methods].find { |m| m[:name] == :subtract }

    param_names = subtract[:params].map { |p| p[:name].to_s.delete_prefix("*").delete_prefix("&") }
    assert_includes param_names, "a"
    assert_includes param_names, "b"
  end

  def test_extracts_method_source
    extractor = Chiridion::Engine::Extractor.new({}, {}, "Sample::", nil)
    structure = extractor.extract(YARD::Registry)

    calculator = structure[:classes].find { |c| c[:path] == "Sample::Calculator" }
    add_method = calculator[:methods].find { |m| m[:name] == :add }

    refute_nil add_method[:source]
    assert_match(/def add/, add_method[:source])
    assert_match(/a \+ b/, add_method[:source])
  end

  def test_computes_source_body_lines
    extractor = Chiridion::Engine::Extractor.new({}, {}, "Sample::", nil)
    structure = extractor.extract(YARD::Registry)

    calculator = structure[:classes].find { |c| c[:path] == "Sample::Calculator" }

    # add method uses one-liner syntax: def add(a, b) = a + b -> 0 body lines
    add_method = calculator[:methods].find { |m| m[:name] == :add }
    assert_equal 0, add_method[:source_body_lines]

    # reset method uses one-liner syntax: def reset = @total = 0 -> 0 body lines
    reset_method = calculator[:methods].find { |m| m[:name] == :reset }
    assert_equal 0, reset_method[:source_body_lines]

    # compute_stats is multi-line - should have several body lines
    stats_method = calculator[:methods].find { |m| m[:name] == :compute_stats }
    assert_operator stats_method[:source_body_lines], :>, 5, "Expected compute_stats to have >5 body lines"
  end

  def test_respects_namespace_filter
    # Without filter - should see top-level Sample module
    extractor_no_filter = Chiridion::Engine::Extractor.new({}, {}, nil, nil)
    structure_no_filter = extractor_no_filter.extract(YARD::Registry)
    all_paths           = (structure_no_filter[:classes] + structure_no_filter[:modules]).map { |o| o[:path] }

    assert(all_paths.any? { |p| p.start_with?("Sample") })

    # With filter - only Sample:: namespace
    extractor_filtered = Chiridion::Engine::Extractor.new({}, {}, "Sample::", nil)
    structure_filtered = extractor_filtered.extract(YARD::Registry)
    filtered_paths     = (structure_filtered[:classes] + structure_filtered[:modules]).map { |o| o[:path] }

    assert(filtered_paths.all? { |p| p.start_with?("Sample::") })
  end

  def test_extracts_see_tags
    extractor = Chiridion::Engine::Extractor.new({}, {}, "Sample::", nil)
    structure = extractor.extract(YARD::Registry)

    helpers = structure[:modules].find { |m| m[:path] == "Sample::Helpers" }

    refute_empty helpers[:see_also]
    assert(helpers[:see_also].any? { |s| s[:name].include?("Calculator") })
  end
end
