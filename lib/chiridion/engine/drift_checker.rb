# frozen_string_literal: true

module Chiridion
  class Engine
    # Detects when documentation is out of sync with source code.
    #
    # Compares what would be generated against existing files.
    # Useful in CI pipelines to enforce documentation currency.
    class DriftChecker
      def initialize(
        output,
        namespace_strip,
        include_specs,
        verbose,
        logger,
        root: Dir.pwd,
        github_repo: nil,
        github_branch: "main",
        project_title: "API Documentation"
      )
        @output = output
        @namespace_strip = namespace_strip
        @include_specs = include_specs
        @verbose = verbose
        @logger = logger
        @renderer = Renderer.new(
          namespace_strip: namespace_strip,
          include_specs: include_specs,
          root: root,
          github_repo: github_repo,
          github_branch: github_branch,
          project_title: project_title
        )
      end

      # Check for drift between source and existing documentation.
      #
      # @param structure [Hash] Documentation structure from Extractor
      # @raise [SystemExit] Exits with code 1 if drift is detected
      def check(structure)
        @renderer.register_classes(structure)

        drifted = []
        missing = []
        orphaned = find_orphaned_files(structure)

        check_index(structure, drifted, missing)
        check_objects(structure[:classes] + structure[:modules], drifted, missing)

        report_results(drifted, missing, orphaned)
      end

      private

      def check_index(structure, drifted, missing)
        path = File.join(@output, "index.md")
        expected = @renderer.render_index(structure)
        check_file(path, expected, drifted, missing)
      end

      def check_objects(objects, drifted, missing)
        objects.each do |obj|
          next unless obj[:needs_regeneration]

          path = output_path(obj[:path])
          expected = obj[:type] == :class ? @renderer.render_class(obj) : @renderer.render_module(obj)
          check_file(path, expected, drifted, missing)
        end
      end

      def check_file(path, expected, drifted, missing)
        if File.exist?(path)
          actual = File.read(path)
          drifted << path if content_changed?(actual, expected)
        else
          missing << path
        end
      end

      def find_orphaned_files(structure)
        return [] unless File.directory?(@output)

        expected_files = Set.new
        expected_files << File.join(@output, "index.md")

        (structure[:classes] + structure[:modules]).each do |obj|
          expected_files << output_path(obj[:path])
        end

        actual_files = Dir.glob("#{@output}/**/*.md")
        actual_files.reject { |f| expected_files.include?(f) }
      end

      def content_changed?(old, new)
        normalize(old) != normalize(new)
      end

      def normalize(content)
        content
          .gsub(/^generated: .+$/, "generated: TIMESTAMP")
          .gsub(/\n{2,}/, "\n\n")
          .strip
      end

      def report_results(drifted, missing, orphaned)
        total_issues = drifted.size + missing.size + orphaned.size

        if total_issues.zero?
          @logger.info "  No drift detected. Documentation is up to date."
          return
        end

        @logger.warn "Documentation drift detected!"
        @logger.warn ""
        report_list("Drifted (content changed)", drifted)
        report_list("Missing (new classes)", missing)
        report_list("Orphaned (classes removed)", orphaned)
        @logger.warn ""
        @logger.warn "Run 'chiridion refresh' to update documentation."

        exit 1
      end

      def report_list(label, files)
        return if files.empty?

        @logger.warn "  #{label}:"
        files.each { |f| @logger.warn "    - #{f}" }
      end

      def output_path(class_path)
        stripped = @namespace_strip ? class_path.sub(/^#{Regexp.escape(@namespace_strip)}/, "") : class_path
        parts = stripped.split("::")
        kebab_parts = parts.map { |p| to_kebab_case(p) }
        File.join(@output, *kebab_parts[0..-2], "#{kebab_parts.last}.md")
      end

      def to_kebab_case(str)
        str.gsub(/([A-Za-z])([vV]\d+)/, '\1-\2')
           .gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
           .gsub(/([a-z\d])([A-Z])/, '\1-\2')
           .downcase
      end
    end
  end
end
