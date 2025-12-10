# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "chiridion"
require "yard"
require "minitest/autorun"
require "minitest/reporters"

# Register @rbs as a known YARD tag to suppress "Unknown tag" warnings
YARD::Tags::Library.define_tag("RBS type annotation", :rbs, :with_types_and_name)

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
