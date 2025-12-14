# frozen_string_literal: true

desc "Documentation generation tasks"

tool "refresh" do
  desc "Regenerate API documentation in docs/sys/"

  def run
    require "logger"
    require_relative "../lib/chiridion"

    Chiridion.configure do |c|
      c.source_path      = "lib/chiridion"
      c.output           = "docs/sys"
      c.namespace_filter = "Chiridion::"
      c.github_repo      = "v2-io/chiridion"
      c.verbose          = verbose?
    end
    Chiridion.refresh
  end
end

tool "check" do
  desc "Check for documentation drift (CI mode)"

  def run
    require "logger"
    require_relative "../lib/chiridion"

    Chiridion.configure do |c|
      c.source_path      = "lib/chiridion"
      c.output           = "docs/sys"
      c.namespace_filter = "Chiridion::"
      c.github_repo      = "v2-io/chiridion"
    end
    Chiridion.check
  end
end
