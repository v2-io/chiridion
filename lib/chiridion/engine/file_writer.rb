# frozen_string_literal: true

require "fileutils"

module Chiridion
  class Engine
    # Writes per-file documentation to disk.
    #
    # Output structure mirrors source structure:
    #   lib/archema/query.rb -> docs/sys/query.md
    #   lib/archema/result.rb -> docs/sys/result.md
    #
    # Handles smart write detection to avoid unnecessary file updates.
    class FileWriter
      def initialize(
        output:,
        logger:, namespace_strip: nil,
        include_specs: false,
        verbose: false,
        root: Dir.pwd,
        github_repo: nil,
        github_branch: "main",
        project_title: "API Documentation",
        index_description: nil,
        inline_source_threshold: 10,
        templates_path: nil
      )
        @output            = output
        @namespace_strip   = namespace_strip
        @verbose           = verbose
        @logger            = logger
        @root              = root
        @index_description = index_description

        @renderer = FileRenderer.new(
          namespace_strip:         namespace_strip,
          include_specs:           include_specs,
          root:                    root,
          github_repo:             github_repo,
          github_branch:           github_branch,
          project_title:           project_title,
          inline_source_threshold: inline_source_threshold,
          templates_path:          templates_path
        )
      end

      # Write all per-file documentation.
      #
      # @param project [ProjectDoc] Documentation structure from SemanticExtractor
      def write(project)
        FileUtils.mkdir_p(@output)

        @renderer.register_classes(project)

        counts = { written: 0, skipped: 0 }

        # Find root file (e.g., lib/archema.rb for Archema::)
        root_file = find_root_file(project.files)

        # Write per-file docs
        project.files.each do |file_doc|
          is_root = root_file && file_doc.path == root_file.path
          write_file_doc(file_doc, counts, is_root: is_root)
        end

        # Always write index.md (root file embeds it via ![[index]])
        write_index(project, counts)

        @logger.info "  #{counts[:written]} files written, #{counts[:skipped]} unchanged"
      end

      # Per-file drift check. Deliberately mirrors #write step-for-step
      # and reuses #output_path / @renderer, so the expected paths and
      # content are exactly what #write would produce — the previous bug
      # was a SECOND, divergent path implementation (DriftChecker's
      # class-name kebab) being used for per_file output. Behavior
      # matches DriftChecker: warn + `exit 1` on drift, quiet otherwise.
      #
      # @param project [ProjectDoc] structure from SemanticExtractor
      # @raise [SystemExit] exit 1 if any drift/missing/orphaned
      def check(project)
        @renderer.register_classes(project)

        root_file = find_root_file(project.files)
        drifted   = []
        missing   = []
        expected  = []

        project.files.each do |file_doc|
          is_root  = root_file && file_doc.path == root_file.path
          path     = output_path(file_doc.path)
          expected << path
          rendered = PostProcessor.process(@renderer.render_file(file_doc, is_root: is_root))
          compare_doc(path, rendered, drifted, missing)
        end

        index_path = File.join(@output, "index.md")
        expected << index_path
        index_doc = PostProcessor.process(@renderer.render_index(project, index_description: @index_description))
        compare_doc(index_path, index_doc, drifted, missing)

        orphaned = Dir.glob("#{@output}/**/*.md").reject { |f| expected.include?(f) }
        report_drift(drifted, missing, orphaned)
      end

      private

      def compare_doc(path, expected_content, drifted, missing)
        if File.exist?(path)
          drifted << path if content_changed?(File.read(path), expected_content)
        else
          missing << path
        end
      end

      def report_drift(drifted, missing, orphaned)
        if (drifted.size + missing.size + orphaned.size).zero?
          @logger.info "  No drift detected. Documentation is up to date."
          return
        end

        @logger.warn "Documentation drift detected!"
        @logger.warn ""
        report_drift_list("Drifted (content changed)", drifted)
        report_drift_list("Missing (new files)", missing)
        report_drift_list("Orphaned (files removed)", orphaned)
        @logger.warn ""
        @logger.warn "Run 'chiridion refresh' to update documentation."

        exit 1
      end

      def report_drift_list(label, files)
        return if files.empty?

        @logger.warn "  #{label}:"
        files.each { |f| @logger.warn "    - #{f}" }
      end

      # Find the root lib file that matches the namespace.
      # e.g., lib/archema.rb for Archema::, lib/chiridion.rb for Chiridion::
      def find_root_file(files)
        return nil unless @namespace_strip

        # Convert Archema:: to archema.rb
        expected_name = @namespace_strip.delete_suffix("::").split("::").last.downcase
        expected_filename = "#{to_snake_case(expected_name)}.rb"

        files.find { |f| f.filename == expected_filename }
      end

      def to_snake_case(str)
        str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
           .gsub(/([a-z\d])([A-Z])/, '\1_\2')
           .gsub("-", "_")
           .downcase
      end

      def write_index(project, counts)
        content                              = @renderer.render_index(project, index_description: @index_description)
        content                              = PostProcessor.process(content)
        wrote                                = write_file(File.join(@output, "index.md"), content)
        counts[wrote ? :written : :skipped] += 1
      end

      def write_file_doc(file_doc, counts, is_root: false)
        path    = output_path(file_doc.path)
        content = @renderer.render_file(file_doc, is_root: is_root)
        content = PostProcessor.process(content)

        FileUtils.mkdir_p(File.dirname(path))
        wrote = write_file(path, content)

        counts[wrote ? :written : :skipped] += 1
        @logger.info "  #{wrote ? 'Wrote' : 'Unchanged'} #{path}" if @verbose
      end

      def write_file(path, new_content)
        new_content = "#{new_content}\n" unless new_content.end_with?("\n")
        return File.write(path, new_content) || true unless File.exist?(path)

        old_content = File.read(path)
        return false unless content_changed?(old_content, new_content)

        File.write(path, new_content)
        true
      end

      def content_changed?(old, new) = normalize(old) != normalize(new)

      def normalize(content)
        content
          .gsub(/^generated: .+$/, "generated: TIMESTAMP")
          .gsub(/\n{2,}/, "\n\n")
          .strip
      end

      # Map source file path to output doc path.
      #
      # lib/archema/query.rb -> docs/sys/query.md
      # lib/archema/result.rb -> docs/sys/result.md
      def output_path(source_path)
        # Strip lib/project_name/ prefix
        path = source_path.sub(%r{\Alib/}, "").sub(/\.rb\z/, "")

        # Strip namespace prefix if configured (e.g., "archema/" from "archema/query")
        if @namespace_strip
          prefix = @namespace_strip.downcase.gsub("::", "/")
          path   = path.sub(%r{\A#{Regexp.escape(prefix)}/?}, "")
        end

        # Convert to kebab-case
        kebab_path = path.split("/").map { |p| to_kebab_case(p) }.join("/")

        File.join(@output, "#{kebab_path}.md")
      end

      def to_kebab_case(str)
        str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
           .gsub(/([a-z\d])([A-Z])/, '\1-\2')
           .gsub("_", "-")
           .downcase
      end
    end
  end
end
