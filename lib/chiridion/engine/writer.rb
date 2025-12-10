# frozen_string_literal: true

require "fileutils"

module Chiridion
  class Engine
    # Writes generated documentation files to disk.
    #
    # Handles smart write detection to avoid unnecessary file updates when
    # only timestamps have changed but content is identical.
    class Writer
      def initialize(
        output,
        namespace_strip,
        include_specs,
        verbose,
        logger,
        root: Dir.pwd,
        github_repo: nil,
        github_branch: "main",
        project_title: "API Documentation",
        index_description: nil,
        inline_source_threshold: 10
      )
        @output          = output
        @namespace_strip = namespace_strip
        @verbose         = verbose
        @logger          = logger
        @root            = root
        @renderer        = Renderer.new(
          namespace_strip:         namespace_strip,
          include_specs:           include_specs,
          root:                    root,
          github_repo:             github_repo,
          github_branch:           github_branch,
          project_title:           project_title,
          index_description:       index_description,
          inline_source_threshold: inline_source_threshold
        )
      end

      # Write all documentation files.
      #
      # @param structure [Hash] Documentation structure from Extractor
      def write(structure)
        FileUtils.mkdir_p(@output)
        written, skipped = write_all_files(structure)
        @logger.info "  #{written} files written, #{skipped} unchanged"
      end

      private

      def write_all_files(structure)
        @renderer.register_classes(structure)

        counts = { written: 0, skipped: 0 }
        write_index(structure, counts)
        write_type_aliases(structure[:type_aliases], counts)
        write_objects(structure[:classes] + structure[:modules], counts)
        [counts[:written], counts[:skipped]]
      end

      def write_type_aliases(type_aliases, counts)
        return if type_aliases.nil? || type_aliases.empty?

        content = @renderer.render_type_aliases(type_aliases)
        return if content.nil?

        wrote                                = write_file(File.join(@output, "type-aliases.md"), content)
        counts[wrote ? :written : :skipped] += 1
      end

      def write_index(structure, counts)
        wrote                                = write_file(File.join(@output, "index.md"),
                                                          @renderer.render_index(structure))
        counts[wrote ? :written : :skipped] += 1
      end

      def write_objects(objects, counts)
        objects.each do |obj|
          next unless obj[:needs_regeneration]

          write_object(obj, counts)
        end
      end

      def write_object(obj, counts)
        path    = output_path(obj[:path])
        content = obj[:type] == :class ? @renderer.render_class(obj) : @renderer.render_module(obj)

        FileUtils.mkdir_p(File.dirname(path))
        wrote = write_file(path, content)

        counts[wrote ? :written : :skipped] += 1
        @logger.info "  #{wrote ? 'Wrote' : 'Unchanged'} #{path}" if @verbose
      end

      def write_file(path, new_content)
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

      def output_path(class_path)
        stripped    = @namespace_strip ? class_path.sub(/^#{Regexp.escape(@namespace_strip)}/, "") : class_path
        parts       = stripped.split("::")
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
