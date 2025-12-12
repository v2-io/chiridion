# frozen_string_literal: true

module Chiridion
  class Engine
    # Renders per-file documentation using Liquid templates.
    #
    # Takes FileDoc structures from SemanticExtractor and produces markdown
    # files grouped by source file rather than by class/module.
    #
    # Design: One markdown file per source file. Each file contains documentation
    # for all namespaces (classes/modules) defined in that source file.
    class FileRenderer
      def initialize(
        namespace_strip: nil,
        include_specs: false,
        root: Dir.pwd,
        github_repo: nil,
        github_branch: "main",
        project_title: "API Documentation",
        inline_source_threshold: 10,
        templates_path: nil
      )
        @namespace_strip         = namespace_strip
        @include_specs           = include_specs
        @root                    = root
        @project_title           = project_title
        @inline_source_threshold = inline_source_threshold
        @class_linker            = ClassLinker.new(namespace_strip: namespace_strip)
        @github_linker           = GithubLinker.new(repo: github_repo, branch: github_branch, root: root)
        @template_renderer       = TemplateRenderer.new(templates_path: templates_path)
      end

      # Register known classes for cross-reference linking.
      #
      # @param project [ProjectDoc] Documentation structure
      def register_classes(project)
        structure = {
          classes: project.classes.map { |c| { path: c.path } },
          modules: project.modules.map { |m| { path: m.path } }
        }
        @class_linker.register_classes(structure)
      end

      # Render documentation for a single source file.
      #
      # @param file_doc [FileDoc] File documentation from SemanticExtractor
      # @param is_root [Boolean] If true, append Obsidian embed for index
      # @return [String] Rendered markdown
      def render_file(file_doc, is_root: false)
        frontmatter = build_file_frontmatter(file_doc, is_root: is_root)

        namespaces_data = file_doc.namespaces.map { |ns| build_namespace_data(ns) }

        body = @template_renderer.render_file(
          path:         file_doc.path,
          filename:     file_doc.filename,
          line_count:   file_doc.line_count,
          namespaces:   namespaces_data,
          type_aliases: []  # Type aliases are now per-namespace
        )

        # If this is the root file, embed the index using Obsidian transclusion
        body = "#{body}\n\n---\n\n![[index]]" if is_root

        "#{render_frontmatter(frontmatter)}\n\n#{body}\n"
      end

      # Render the documentation index.
      #
      # @param project [ProjectDoc] Documentation structure
      # @param index_description [String, nil] Custom description
      # @return [String] Rendered markdown
      def render_index(project, index_description: nil)
        frontmatter = {
          generated:   project.generated_at.iso8601,
          title:       @project_title,
          type:        "index",
          description: index_description || "Auto-generated from source code."
        }

        # Group by file for per-file index
        files = project.files.map do |f|
          link_path = source_to_link(f.path)
          primary   = f.primary_namespace
          {
            path:       f.path,
            link_path:  link_path,
            filename:   f.filename,
            namespaces: f.namespaces.map(&:path).join(", "),
            primary:    primary&.path || f.filename
          }
        end

        body = render_file_index(files)

        "#{render_frontmatter(frontmatter)}\n\n#{body}\n"
      end

      private

      def build_file_frontmatter(file_doc, is_root: false)
        primary = file_doc.primary_namespace

        fm = {
          generated:   Time.now.utc.iso8601,
          title:       is_root ? @project_title : file_doc.filename,
          source:      file_doc.path,
          source_url:  @github_linker.url(file_doc.path, 1, nil),
          lines:       file_doc.line_count,
          type:        is_root ? "index" : "file",
          parent:      is_root ? nil : file_parent(file_doc.path),
          primary:     primary&.path,
          namespaces:  file_doc.namespaces.map(&:path),
          tags:        build_file_tags(file_doc, is_root: is_root),
          description: build_file_description(file_doc, primary)
        }

        # Add method lists for each namespace
        file_doc.namespaces.each do |ns|
          key = "#{to_kebab_case(ns.name)}-methods"
          methods = build_method_signatures(ns)
          fm[key.to_sym] = methods unless methods.empty?
        end

        fm.compact
      end

      # Build method signatures for frontmatter like ["ClassName.new(arg1, arg2)", "method_name(path)"]
      def build_method_signatures(ns)
        class_name = ns.name.to_s.split("::").last

        signatures = ns.methods.map do |m|
          name = if m.name == :initialize
                   "#{class_name}.new"
                 elsif m.scope == :class
                   "#{class_name}.#{m.name}"
                 else
                   m.name.to_s
                 end

          if m.params.any?
            param_names = m.params.map { |p| "#{p.prefix}#{p.name}" }.join(", ")
            name += "(#{param_names})"
          end
          name
        end

        signatures.sort_by(&:downcase)
      end

      # Extract parent directory for navigation (e.g., "dsl" from "lib/archema/dsl/attrs.rb")
      def file_parent(path)
        dir = File.dirname(path).sub(%r{\Alib/}, "")
        return nil if dir == "." || dir.empty?

        # Strip namespace prefix if configured
        if @namespace_strip
          prefix = @namespace_strip.downcase.gsub("::", "/")
          dir = dir.sub(%r{\A#{Regexp.escape(prefix)}/?}, "")
        end

        dir.empty? ? nil : dir
      end

      # Build a sensible description for the file
      def build_file_description(file_doc, primary)
        # If single namespace, use its docstring
        if file_doc.namespaces.size == 1
          return primary&.docstring&.lines&.first&.strip || ""
        end

        # If primary has a docstring, use it
        if primary&.docstring && !primary.docstring.empty?
          return primary.docstring.lines.first.strip
        end

        # Fall back to listing namespace count
        classes = file_doc.classes.size
        modules = file_doc.modules.size
        parts = []
        parts << "#{classes} class#{'es' if classes != 1}" if classes.positive?
        parts << "#{modules} module#{'s' if modules != 1}" if modules.positive?
        parts.any? ? "Contains #{parts.join(' and ')}." : ""
      end

      def build_file_tags(file_doc, is_root: false)
        tags = [is_root ? "index" : "file"]
        file_doc.namespaces.each do |ns|
          tags << ns.type.to_s
          tags << "abstract" if ns.abstract
          tags << "deprecated" if ns.deprecated
        end
        tags.uniq
      end

      def build_namespace_data(ns)
        docstring = @class_linker.linkify_docstring(ns.docstring, context: ns.path)

        {
          name:              ns.name,
          path:              ns.path,
          type:              ns.type.to_s,
          superclass:        ns.superclass ? linkify_class(ns.superclass, ns.path) : nil,
          abstract:          ns.abstract,
          deprecated:        ns.deprecated,
          docstring:         docstring,
          mixins:            render_mixins(ns),
          notes:             ns.notes,
          see_also:          ns.see_also.map { |s| { target: linkify_class(s.target, ns.path), text: s.text } },
          examples:          ns.examples.map { |e| { name: e.name, code: e.code } },
          type_aliases:      ns.type_aliases.map { |t| { name: t.name, definition: t.definition, description: t.description } },
          constants_section: render_constants(ns.constants),
          types_section:     render_types_section(ns.referenced_types),
          summary_section:   render_summary_section(ns.attributes, ns.methods, ns.path),
          methods_section:   render_methods_section(ns.methods, ns.path),
          private_summary:   render_private_summary(ns.private_methods)
        }
      end

      def linkify_class(name, context) = @class_linker.link(name, context: context)

      def render_mixins(ns)
        return nil unless ns.includes.any? || ns.extends.any?

        parts = []
        if ns.includes.any?
          linked = ns.includes.map { |m| linkify_class(m, ns.path) }
          parts << "**Includes:** #{linked.join(', ')}"
        end
        if ns.extends.any?
          linked = ns.extends.map { |m| linkify_class(m, ns.path) }
          parts << "**Extends:** #{linked.join(', ')}"
        end
        parts.join(" · ")
      end

      def render_constants(constants)
        return "" if constants.empty?

        simple, complex = constants.partition { |c| simple_constant?(c) }

        lines = ["## Constants", ""]

        if simple.any?
          lines << "| Name | Value | Description |"
          lines << "|------|-------|-------------|"
          simple.each do |c|
            value = c.value.to_s.delete_suffix(".freeze").gsub("|", "\\|").gsub("\n", " ")[0, 60]
            desc  = c.description.to_s.gsub("|", "\\|").gsub("\n", " ")
            lines << "| `#{c.name}` | `#{value}` | #{desc} |"
          end
        end

        complex.each do |c|
          lines << ""
          lines << "### #{c.name}"
          lines << ""
          lines << c.description if c.description && !c.description.empty?
          lines << ""
          lines << "```ruby"
          lines << c.value.to_s.delete_suffix(".freeze")
          lines << "```"
        end

        lines.join("\n")
      end

      def simple_constant?(c)
        return false if c.value.to_s.count("\n") > 1
        return false if c.description.to_s.count("\n") > 1
        return false if c.description.to_s.length > 80

        true
      end

      def render_types_section(referenced_types)
        return "" if referenced_types.nil? || referenced_types.empty?

        lines = ["## Types Used", ""]
        referenced_types.each do |t|
          desc = t.description ? " — #{t.description}" : ""
          lines << "- `#{t.name}` = `#{t.definition}`#{desc}"
        end
        lines.join("\n")
      end


      # Render combined Attributes / Methods summary section.
      #
      # Format:
      #   `⟨attr_name          : Type⟩` (Read) — description
      #   `⟨method_name(…)     : ReturnType⟩` — summary
      #
      # Methods show (…) if they have params, and use their return type.
      # Only the summary portion of method docstrings is used.
      def render_summary_section(attributes, methods, context)
        return "" if attributes.empty? && methods.empty?

        lines = ["## Attributes / Methods", ""]

        # Build parts for attributes
        attr_parts = attributes.sort_by(&:name).map do |attr|
          type_str = attr.type ? " : #{attr.type}" : ""
          mode = case attr.mode
                 when :read then "Read"
                 when :write then "Write"
                 end

          # Take only first non-blank line of description
          desc = attr.description&.lines&.map(&:strip)&.reject(&:empty?)&.first

          # If has description, show "— desc", else if has mode, show "— (Mode)"
          suffix = if desc
                     ""
                   elsif mode
                     " — (#{mode})"
                   else
                     ""
                   end

          { name: attr.name.to_s, type: type_str, suffix: suffix, desc: desc }
        end

        # Build parts for methods (excluding initialize which is covered by return type)
        meth_parts = methods.reject { |m| m.name == :initialize }.sort_by { |m| m.name.to_s }.map do |meth|
          name = meth.name.to_s
          name += "(…)" if meth.params.any?

          # Get return type
          ret_type = nil
          if meth.returns&.type
            ret_type = meth.returns.type
            ret_type = nil if ret_type == "void"
          end
          type_str = ret_type ? " : #{ret_type}" : ""

          # Get first non-blank line of docstring only
          summary = nil
          if meth.docstring && !meth.docstring.empty?
            linkified = @class_linker.linkify_docstring(meth.docstring, context: context)
            # Take only the first non-blank line
            summary = linkified.lines.map(&:strip).reject(&:empty?).first
          end

          { name: name, type: type_str, suffix: "", desc: summary }
        end

        all_parts = attr_parts + meth_parts
        return "" if all_parts.empty?

        # Calculate column widths
        max_name = all_parts.map { |p| p[:name].length }.max

        # Build content strings (without brackets) to measure
        contents = all_parts.map do |p|
          "#{p[:name].ljust(max_name)}#{p[:type]}"
        end
        max_content = contents.map(&:length).max

        # Render aligned with padding inside brackets: `⟨content         ⟩`
        all_parts.each_with_index do |p, i|
          padded_content = contents[i].ljust(max_content)
          desc_part = p[:desc] ? " — #{capitalize_first(p[:desc])}" : ""
          lines << "`⟨#{padded_content}⟩`#{p[:suffix]}#{desc_part}"
        end

        lines.join("\n")
      end

      def render_methods_section(methods, context)
        return "" if methods.empty?

        lines = ["## Methods", ""]

        methods.sort_by { |m| [m.scope == :class ? 0 : 1, m.name.to_s] }.each_with_index do |meth, i|
          lines << "---" if i.positive?
          lines << ""
          lines.concat(render_method(meth, context))
        end

        lines.join("\n")
      end

      def render_method(meth, context)
        lines = []

        # Method header
        display_name = method_display_name(meth, context)
        params_hint  = meth.params.any? ? "(...)" : ""
        # Escape ( after [] to prevent markdown link interpretation: ### [](...)
        params_hint = "\\#{params_hint}" if display_name.end_with?("[]") && params_hint.start_with?("(")
        lines << "### #{display_name}#{params_hint}"

        # Deprecation/abstract warnings
        lines << "" << "> **Deprecated:** #{meth.deprecated}" if meth.deprecated
        lines << "" << "> **Abstract:** Must be implemented by subclasses." if meth.abstract

        # Docstring handling:
        # - If first line is followed by blank line or ## header, it's a summary (goes above params)
        # - Rest of docstring goes below the signature
        summary = nil
        description = nil
        if meth.docstring && !meth.docstring.empty?
          linkified = @class_linker.linkify_docstring(meth.docstring, context: context)
          summary, description = split_docstring(linkified)

          if summary
            lines << ""
            lines << summary
          end
        end

        # Parameters and return (aligned together)
        sig_lines = render_signature(meth, context)
        if sig_lines.any?
          lines << ""
          lines.concat(sig_lines)
        end

        # Options
        if meth.options.any?
          lines << ""
          lines << "**Options:**"
          meth.options.each do |opt|
            type_str = opt.type ? " : #{opt.type}" : ""
            desc     = opt.description ? " — #{opt.description}" : ""
            lines << "- `:#{opt.key}`#{type_str}#{desc}"
          end
        end

        # Description (rest of docstring) goes after signature
        if description && !description.empty?
          lines << ""
          lines << description
        end

        # Yields/block
        if meth.yields
          lines << ""
          lines << "**Block:**"
          lines << meth.yields.description if meth.yields.description
          if meth.yields.params.any?
            meth.yields.params.each do |p|
              type_str = p.type ? " : #{p.type}" : ""
              desc     = p.description ? " — #{p.description}" : ""
              lines << "- `#{p.name}#{type_str}`#{desc}"
            end
          end
          if meth.yields.return_type
            desc = meth.yields.return_desc ? " — #{meth.yields.return_desc}" : ""
            lines << "- Returns: `#{meth.yields.return_type}`#{desc}"
          end
        end

        # Raises
        if meth.raises.any?
          lines << ""
          lines << "**Raises:**"
          meth.raises.each do |r|
            desc = r.description && !r.description.strip.empty? ? " — #{r.description}" : ""
            lines << "`#{r.type}`#{desc}"
          end
        end

        # Examples
        meth.examples.each do |ex|
          lines << ""
          header = ex.name && !ex.name.empty? ? "#### Example: #{ex.name}" : "#### Example"
          lines << header
          lines << ""
          lines << "```ruby"
          lines << ex.code
          lines << "```"
        end

        # Notes
        meth.notes.each do |note|
          lines << ""
          lines << "> **Note:** #{note}"
        end

        # See also
        if meth.see_also.any?
          links = meth.see_also.map { |s| linkify_class(s.target, context) }
          lines << ""
          lines << "**See also:** #{links.join(', ')}"
        end

        # Inline source
        if @inline_source_threshold&.positive? && meth.source && meth.source_body_lines &&
           meth.source_body_lines <= @inline_source_threshold
          lines << ""
          lines << "#### Source"
          lines << ""
          if meth.file && meth.line
            rel_path = make_relative(meth.file)
            lines << "```ruby"
            lines << "# #{rel_path}:#{meth.line}"
            lines << meth.source
            lines << "```"
          else
            lines << "```ruby"
            lines << meth.source
            lines << "```"
          end
        end

        lines
      end

      def method_display_name(meth, context)
        class_name = context.split("::").last
        return "#{class_name}.new" if meth.name == :initialize
        return "#{class_name}.#{meth.name}" if meth.scope == :class

        meth.name.to_s
      end

      # Render params and return with aligned columns for readability.
      #
      # Output format:
      #   `⟨name         : Type⟩                ` — Description
      #   `⟨longer_name  : OtherType = default⟩` — Another description
      #   ⟶ `ReturnType                        ` — Return description
      #
      # Return is shown:
      # - For initialize: class name (even if void)
      # - For explicit void: shows `void`
      # - For other types: shows the type
      # - For undeclared (nil returns): nothing shown
      #
      # @param meth [MethodDoc] Method documentation
      # @param context [String] Class context for initialize handling
      # @return [Array<String>]
      def render_signature(meth, context)
        # Build raw parts for each param
        parts = meth.params.map do |p|
          prefix   = p.prefix || ""
          name     = "#{prefix}#{p.name}"
          type_str = p.type ? " : #{p.type}" : ""
          default  = p.default ? " = #{p.default}" : ""
          desc     = p.description&.strip
          desc     = nil if desc&.empty?

          { name: name, type_default: "#{type_str}#{default}", desc: desc, kind: :param }
        end

        # Determine return type to show (if any)
        ret_type = nil
        ret_desc = nil
        if meth.returns
          ret_type = meth.returns.type
          ret_desc = meth.returns.description&.strip
          ret_desc = nil if ret_desc&.empty?

          # For initialize, use class name instead of void
          if meth.name == :initialize && ret_type == "void"
            ret_type = context.split("::").last
          end
          # Explicit void is shown (distinguishes from undeclared)
        end

        return [] if parts.empty? && ret_type.nil?

        # Calculate column widths
        max_name = parts.map { |p| p[:name].length }.max || 0

        # Build param content strings (without brackets) to measure
        param_contents = parts.map do |p|
          padded_name = p[:name].ljust(max_name)
          "#{padded_name}#{p[:type_default]}"
        end

        # Max content width considers both params and return type
        # For return, subtract 1 to account for "⟶ " prefix alignment
        max_content = param_contents.map(&:length).max || 0
        ret_content_width = ret_type ? ret_type.length : 0
        max_content = [max_content, ret_content_width + 1].max  # +1 so return aligns when -1 applied

        # Render params with padding inside brackets: `⟨content         ⟩`
        lines = parts.each_with_index.map do |p, i|
          padded_content = param_contents[i].ljust(max_content)
          desc_part = p[:desc] ? " — #{p[:desc]}" : ""
          "`⟨#{padded_content}⟩`#{desc_part}"
        end

        # Render return (inline with params, no blank line)
        # Reduce padding by 1 to compensate for "⟶ " prefix
        if ret_type
          ret_pad = [max_content - 1, ret_type.length].max
          padded_type = ret_type.ljust(ret_pad)
          desc_part = ret_desc ? " — #{capitalize_first(ret_desc)}" : ""
          lines << "⟶ `#{padded_type}`#{desc_part}"
        end

        lines
      end

      # Split docstring into summary (first line) and description (rest).
      #
      # Summary is extracted if first line is followed by:
      # - A blank line (two consecutive newlines)
      # - A markdown header (## or ###)
      #
      # @param docstring [String] Full docstring text
      # @return [Array(String, String), Array(String, nil)] [summary, description]
      def split_docstring(docstring)
        return [nil, nil] if docstring.nil? || docstring.empty?

        lines = docstring.lines
        return [docstring.strip, nil] if lines.size == 1

        first_line = lines[0].strip
        second_line = lines[1]

        # Check if second line is blank or a header
        has_break = second_line.strip.empty? || second_line.match?(/\A\#{2,3}\s/)

        if has_break
          rest = lines[1..].join.strip
          rest = nil if rest.empty?
          [first_line, rest]
        else
          # No clear break - treat whole thing as description if long, else as summary
          if lines.size <= 2
            [docstring.strip, nil]
          else
            [nil, docstring.strip]
          end
        end
      end

      def render_private_summary(private_methods)
        return "" if private_methods.empty?

        sorted = private_methods.sort_by { |m| [m.scope == :class ? 0 : 1, m.name.to_s] }
        items  = sorted.map do |m|
          prefix = m.scope == :class ? "." : "#"
          line   = m.line ? ":#{m.line}" : ""
          "`#{prefix}#{m.name}`#{line}"
        end

        "---\n\n**Private:** #{items.join(', ')}"
      end

      def render_file_index(files)
        lines = ["# #{@project_title}", "", "> Per-file API documentation", "", "## Files", ""]

        files.each do |f|
          lines << "- [[#{f[:link_path]}|#{f[:filename]}]] — #{f[:namespaces]}"
        end

        lines.join("\n")
      end

      def render_frontmatter(frontmatter)
        lines = ["---"]
        frontmatter.each do |key, value|
          next if value.nil?

          if value.is_a?(Array)
            # Quote items containing [] to avoid YAML parsing as arrays
            quoted_values = value.map { |v| v.to_s.include?("[") ? "\"#{v}\"" : v }
            # Try flow-style first, use block-style if > 80 chars
            flow_line = "#{key}: [#{quoted_values.join(', ')}]"
            if flow_line.length <= 80
              lines << flow_line
            else
              lines << "#{key}:"
              quoted_values.each { |v| lines << "  - #{v}" }
            end
          else
            lines << "#{key}: #{value}"
          end
        end
        lines << "---"
        lines.join("\n")
      end

      def make_relative(path)
        return path unless path&.start_with?(@root)

        path.delete_prefix("#{@root}/")
      end

      def source_to_link(source_path)
        # lib/archema/query.rb -> query
        # Strip lib/project/ prefix and .rb extension
        path = source_path.sub(%r{\Alib/}, "").sub(/\.rb\z/, "")

        # Strip namespace prefix if configured
        if @namespace_strip
          prefix = @namespace_strip.downcase.gsub("::", "/")
          path   = path.sub(%r{\A#{Regexp.escape(prefix)}/?}, "")
        end

        to_kebab_case(path)
      end

      def to_kebab_case(str)
        str.gsub("/", "/")
           .gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
           .gsub(/([a-z\d])([A-Z])/, '\1-\2')
           .gsub("_", "-")
           .downcase
      end

      # Capitalize the first letter of a string, preserving the rest.
      def capitalize_first(str)
        return nil if str.nil? || str.strip.empty?

        s = str.strip
        s[0].upcase + s[1..]
      end
    end
  end
end
