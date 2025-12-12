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

      private

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
