# frozen_string_literal: true

require "test_helper"

class ClassLinkerTest < Minitest::Test
  def setup
    @linker = Chiridion::Engine::ClassLinker.new(namespace_strip: "MyProject::")
    @linker.register_classes({
                               classes: [
                                 { path: "MyProject::Config" },
                                 { path: "MyProject::Engine" },
                                 { path: "MyProject::Engine::Extractor" }
                               ],
                               modules: [
                                 { path: "MyProject::Helpers" }
                               ]
                             })
  end

  def test_generates_wikilink_for_known_class
    link = @linker.link("MyProject::Config", context: "MyProject::Engine")

    # Format is [[path|DisplayName]]
    assert_equal "[[config|Config]]", link
  end

  def test_strips_namespace_from_link_path
    link = @linker.link("MyProject::Config", context: "MyProject::Engine")

    # Path part should be just "config", not "my-project/config"
    assert_equal "[[config|Config]]", link
  end

  def test_returns_display_name_for_unknown_class
    link = @linker.link("UnknownClass", context: "MyProject::Engine")

    # Should not be a wikilink, just the display name
    refute_match(/\[\[/, link)
    assert_equal "UnknownClass", link
  end

  def test_linkifies_curly_brace_references_in_docstring
    # linkify_docstring only converts {Class} format, not bare class names
    docstring = "See {Config} for configuration options."
    result    = @linker.linkify_docstring(docstring, context: "MyProject::Engine")

    assert_equal "See [[config|Config]] for configuration options.", result
  end

  def test_preserves_text_around_links_in_docstring
    docstring = "Use {Config} to configure."
    result    = @linker.linkify_docstring(docstring, context: "MyProject::Engine")

    assert_match(/^Use /, result)
    assert_match(/ to configure\.$/, result)
  end

  def test_handles_nested_class_references
    link = @linker.link("MyProject::Engine::Extractor", context: "MyProject::Config")

    # Nested path becomes engine/extractor
    assert_equal "[[engine/extractor|Extractor]]", link
  end

  def test_linker_without_namespace_strip
    linker = Chiridion::Engine::ClassLinker.new(namespace_strip: nil)
    linker.register_classes({
                              classes: [{ path: "Foo::Bar" }],
                              modules: []
                            })

    link = linker.link("Foo::Bar", context: "Other")

    # Without strip, full path is used
    assert_equal "[[foo/bar|Bar]]", link
  end

  def test_resolves_short_name_in_context
    # Can use short name "Config" which resolves via registered short names
    link = @linker.link("Config", context: "MyProject::Engine")

    assert_equal "[[config|Config]]", link
  end

  def test_known_class_check
    assert @linker.known?("MyProject::Config")
    assert @linker.known?("Config") # Short name also registered
    refute @linker.known?("UnknownClass")
  end
end
