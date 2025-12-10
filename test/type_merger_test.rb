# frozen_string_literal: true

require "test_helper"

class TypeMergerTest < Minitest::Test
  def setup = @merger = Chiridion::Engine::TypeMerger.new(nil)

  def test_rbs_params_take_precedence_over_yard
    yard_params = [
      { name: "a", types: ["Object"], text: "first param" },
      { name: "b", types: ["Object"], text: "second param" }
    ]

    rbs_data = {
      params:  { "a" => "Integer", "b" => "String" },
      returns: "Boolean"
    }

    merged = @merger.merge_params(yard_params, rbs_data, "TestClass", :test_method)

    a_param = merged.find { |p| p[:name] == "a" }
    b_param = merged.find { |p| p[:name] == "b" }

    assert_equal ["Integer"], a_param[:types]
    assert_equal ["String"], b_param[:types]
    # Text should be preserved from YARD
    assert_equal "first param", a_param[:text]
  end

  def test_uses_yard_types_when_no_rbs
    yard_params = [
      { name: "x", types: ["Numeric"], text: "a number" }
    ]

    merged = @merger.merge_params(yard_params, nil, "TestClass", :test_method)

    x_param = merged.find { |p| p[:name] == "x" }
    assert_equal ["Numeric"], x_param[:types]
  end

  def test_rbs_return_takes_precedence
    yard_return = { types: ["Object"], text: "the result" }
    rbs_data    = { returns: "Integer" }

    merged = @merger.merge_return(yard_return, rbs_data, "TestClass", :test_method)

    assert_equal ["Integer"], merged[:types]
    assert_equal "the result", merged[:text]
  end

  def test_uses_yard_return_when_no_rbs
    yard_return = { types: ["String"], text: "a string" }

    merged = @merger.merge_return(yard_return, nil, "TestClass", :test_method)

    assert_equal ["String"], merged[:types]
  end

  def test_handles_empty_yard_params
    # When yard_params is empty, result is empty regardless of RBS data
    rbs_data = {
      params:  { "a" => "Integer" },
      returns: "void"
    }

    merged = @merger.merge_params([], rbs_data, "TestClass", :test_method)

    assert_empty merged
  end

  def test_handles_nil_yard_return
    rbs_data = { returns: "String" }

    merged = @merger.merge_return(nil, rbs_data, "TestClass", :test_method)

    assert_equal ["String"], merged[:types]
    assert_nil merged[:text]
  end

  def test_preserves_param_defaults
    yard_params = [
      { name: "limit", types: ["Integer"], text: "max items", default: "10" }
    ]

    rbs_data = {
      params: { "limit" => "Integer" }
    }

    merged = @merger.merge_params(yard_params, rbs_data, "TestClass", :test_method)

    limit_param = merged.find { |p| p[:name] == "limit" }
    assert_equal "10", limit_param[:default]
  end
end
