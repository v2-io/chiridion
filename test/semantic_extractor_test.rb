# frozen_string_literal: true

require "test_helper"
require "chiridion/engine/document_model"
require "chiridion/engine/semantic_extractor"
require "chiridion/engine/type_merger"

class SemanticExtractorTest < Minitest::Test
  include Chiridion::Engine::DocumentModel

  def setup
    @rbs_types = {
      "TestModule::TestClass" => {
        "initialize" => {
          full:    "(String name, ?Integer age) -> void",
          params:  { "name" => { type: "String", desc: "The name" }, "age" => { type: "Integer", desc: nil } },
          returns: { type: "void", desc: nil }
        },
        "greet"      => {
          full:    "(String? message) -> String",
          params:  { "message" => { type: "String?", desc: "Optional greeting" } },
          returns: { type: "String", desc: "The greeting" }
        }
      }
    }

    @rbs_ivar_types = {
      "TestModule::TestClass" => {
        "name" => { type: "String", desc: nil },
        "age"  => { type: "Integer?", desc: nil }
      }
    }

    @rbs_attr_types = {
      "TestModule::TestClass" => {
        "name" => { type: "String", desc: "The person's name" }
      }
    }

    @type_aliases = {
      "TestModule" => [
        { name: "context_value", definition: "Symbol | String", description: "Context values" }
      ]
    }

    @extractor = Chiridion::Engine::SemanticExtractor.new(
      rbs_types:        @rbs_types,
      rbs_attr_types:   @rbs_attr_types,
      rbs_ivar_types:   @rbs_ivar_types,
      type_aliases:     @type_aliases,
      spec_examples:    {},
      namespace_filter: nil,
      logger:           nil
    )
  end

  def test_param_doc_from_hash
    h     = { name: "foo", types: ["String"], text: "The foo param", default: "nil" }
    param = ParamDoc.from_hash(h)

    assert_equal "foo", param.name
    assert_equal "String", param.type
    assert_equal "The foo param", param.description
    assert_equal "nil", param.default
  end

  def test_param_doc_prefix_extraction
    assert_equal "*", ParamDoc.extract_prefix("*args")
    assert_equal "**", ParamDoc.extract_prefix("**kwargs")
    assert_equal "&", ParamDoc.extract_prefix("&block")
    assert_nil ParamDoc.extract_prefix("regular")
  end

  def test_example_doc_structure
    example = ExampleDoc.new(name: "Basic usage", code: "foo.bar")
    assert_equal "Basic usage", example.name
    assert_equal "foo.bar", example.code
  end

  def test_ivar_doc_structure
    ivar = IvarDoc.new(name: "counter", type: "Integer", description: "A counter")
    assert_equal "counter", ivar.name
    assert_equal "Integer", ivar.type
    assert_equal "A counter", ivar.description
  end

  def test_type_alias_doc_structure
    type_alias = TypeAliasDoc.new(
      name:        "user_id",
      definition:  "String | Integer",
      description: "User identifier",
      namespace:   "MyApp"
    )
    assert_equal "user_id", type_alias.name
    assert_equal "String | Integer", type_alias.definition
    assert_equal "User identifier", type_alias.description
    assert_equal "MyApp", type_alias.namespace
  end

  def test_method_doc_structure
    method_doc = MethodDoc.new(
      name:              :greet,
      scope:             :instance,
      visibility:        :public,
      signature:         "def greet(message = nil)",
      docstring:         "Greets someone",
      params:            [ParamDoc.new(name: "message", type: "String?", description: nil, default: "nil",
                                       prefix: nil)],
      options:           [],
      returns:           ReturnDoc.new(type: "String", description: "The greeting"),
      yields:            nil,
      raises:            [],
      examples:          [],
      notes:             [],
      see_also:          [],
      api:               nil,
      deprecated:        nil,
      abstract:          false,
      since:             nil,
      todo:              nil,
      rbs_signature:     "(String? message) -> String",
      overloads:         [],
      source:            "def greet(message = nil)\n  \"Hello\"\nend",
      source_body_lines: 1,
      attr_type:         nil,
      file:              "lib/test.rb",
      line:              42,
      spec_examples:     [],
      spec_behaviors:    []
    )

    assert_equal :greet, method_doc.name
    assert_equal :instance, method_doc.scope
    assert_equal :public, method_doc.visibility
    assert_equal 1, method_doc.params.size
    assert_equal "String", method_doc.returns.type
  end

  def test_yield_doc_structure
    yield_doc = YieldDoc.new(
      description: "Yields control to block",
      params:      [ParamDoc.new(name: "item", type: "String", description: "The item", default: nil, prefix: nil)],
      return_type: "void",
      return_desc: nil,
      block_type:  "^(String) -> void"
    )

    assert_equal "Yields control to block", yield_doc.description
    assert_equal 1, yield_doc.params.size
    assert_equal "void", yield_doc.return_type
    assert_equal "^(String) -> void", yield_doc.block_type
  end

  def test_raise_doc_structure
    raise_doc = RaiseDoc.new(type: "ArgumentError", description: "When name is nil")
    assert_equal "ArgumentError", raise_doc.type
    assert_equal "When name is nil", raise_doc.description
  end

  def test_namespace_doc_structure
    ns = NamespaceDoc.new(
      name:             "TestClass",
      path:             "TestModule::TestClass",
      type:             :class,
      superclass:       "Object",
      docstring:        "A test class",
      examples:         [],
      notes:            ["This is a note"],
      see_also:         [],
      api:              nil,
      deprecated:       nil,
      abstract:         false,
      since:            "1.0",
      todo:             nil,
      includes:         ["Comparable"],
      extends:          [],
      constants:        [],
      type_aliases:     [],
      ivars:            [],
      attributes:       [],
      methods:          [],
      private_methods:  [],
      file:             "lib/test.rb",
      line:             1,
      end_line:         100,
      rbs_file:         nil,
      spec_examples:    nil,
      referenced_types: []
    )

    assert_equal "TestClass", ns.name
    assert_equal "TestModule::TestClass", ns.path
    assert_equal :class, ns.type
    assert_equal "Object", ns.superclass
    assert_equal ["This is a note"], ns.notes
    assert_equal "1.0", ns.since
    assert_equal ["Comparable"], ns.includes
  end

  def test_project_doc_helpers
    ns_class = NamespaceDoc.new(
      name: "MyClass", path: "MyClass", type: :class, superclass: nil,
      docstring: nil, examples: [], notes: [], see_also: [],
      api: nil, deprecated: nil, abstract: false, since: nil, todo: nil,
      includes: [], extends: [], constants: [], type_aliases: [], ivars: [],
      attributes: [], methods: [], private_methods: [],
      file: nil, line: nil, end_line: nil, rbs_file: nil, spec_examples: nil,
      referenced_types: []
    )

    ns_module = NamespaceDoc.new(
      name: "MyModule", path: "MyModule", type: :module, superclass: nil,
      docstring: nil, examples: [], notes: [], see_also: [],
      api: nil, deprecated: nil, abstract: false, since: nil, todo: nil,
      includes: [], extends: [], constants: [], type_aliases: [], ivars: [],
      attributes: [], methods: [], private_methods: [],
      file: nil, line: nil, end_line: nil, rbs_file: nil, spec_examples: nil,
      referenced_types: []
    )

    project = ProjectDoc.new(
      title:        "Test Project",
      description:  "A test",
      namespaces:   [ns_class, ns_module],
      files:        [],
      type_aliases: {},
      generated_at: Time.now
    )

    assert_equal 1, project.classes.size
    assert_equal 1, project.modules.size
    assert_equal "MyClass", project.classes.first.name
    assert_equal "MyModule", project.modules.first.name
  end
end
