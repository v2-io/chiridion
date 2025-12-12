# frozen_string_literal: true

require "json"
require "yaml"

module Chiridion
  class Engine
    # Simplified semantic renderer that outputs structured data.
    #
    # Rather than formatting for human reading, this outputs all extracted
    # semantic data as JSON (or simple markdown with JSON payload). This helps:
    #
    # 1. Verify what data is being captured vs. missed
    # 2. Debug the extraction pipeline
    # 3. Provide machine-readable documentation for LLMs/agents
    # 4. Separate concerns: extraction vs. presentation
    #
    # Output format: YAML frontmatter + JSON code fence with all data.
    class SemanticRenderer
      def initialize(namespace_strip: nil, project_title: "API Documentation")
        @namespace_strip = namespace_strip
        @project_title   = project_title
      end

      # Render complete project documentation.
      #
      # @param project [ProjectDoc] Complete documentation from SemanticExtractor
      # @return [Hash{String => String}] filename -> content mapping
      def render(project)
        files = {}

        # Index
        files["index.md"] = render_index(project)

        # Type aliases are embedded where used (in each namespace's referenced_types)
        # No separate types.md needed.

        # Each namespace
        project.namespaces.each do |ns|
          filename        = namespace_to_filename(ns.path)
          files[filename] = render_namespace(ns)
        end

        files
      end

      # Render index page.
      def render_index(project)
        frontmatter = {
          "generated"    => project.generated_at.iso8601,
          "title"        => @project_title,
          "type"         => "index",
          "description"  => project.description || "Auto-generated API documentation",
          "class_count"  => project.classes.size,
          "module_count" => project.modules.size
        }

        classes = project.classes.map { |c| { path: c.path, file: c.file } }
        modules = project.modules.map { |m| { path: m.path, file: m.file } }

        body_data = {
          classes: classes,
          modules: modules
        }

        render_document(frontmatter, body_data)
      end

      # Render type aliases reference.
      def render_type_aliases(project)
        frontmatter = {
          "generated"   => project.generated_at.iso8601,
          "title"       => "Type Aliases Reference",
          "type"        => "reference",
          "description" => "RBS type aliases defined across the codebase"
        }

        # Convert DocumentModel structs to hashes for JSON
        aliases_by_namespace = project.type_aliases.transform_values do |types|
          types.map { |t| type_alias_to_hash(t) }
        end

        body_data = { type_aliases: aliases_by_namespace }

        render_document(frontmatter, body_data)
      end

      # Render a namespace (class or module).
      def render_namespace(ns)
        frontmatter = build_frontmatter(ns)
        body_data   = build_body_data(ns)

        render_document(frontmatter, body_data)
      end

      private

      def build_frontmatter(ns)
        fm = {
          "generated"   => Time.now.utc.iso8601,
          "title"       => ns.path,
          "type"        => ns.type.to_s,
          "description" => ns.docstring.to_s.lines.first&.strip || "",
          "source"      => ns.file ? "#{ns.file}:#{ns.line}" : nil,
          "tags"        => build_tags(ns)
        }

        fm["inherits"]   = ns.superclass if ns.superclass
        fm["api"]        = ns.api if ns.api
        fm["deprecated"] = ns.deprecated if ns.deprecated
        fm["abstract"]   = true if ns.abstract
        fm["since"]      = ns.since if ns.since

        fm.compact
      end

      def build_tags(ns)
        tags = [ns.type.to_s]
        tags << "abstract" if ns.abstract
        tags << "deprecated" if ns.deprecated
        tags << ns.api if ns.api
        tags.compact
      end

      def build_body_data(ns)
        {
          identity:        {
            name:       ns.name,
            path:       ns.path,
            type:       ns.type,
            superclass: ns.superclass,
            file:       ns.file,
            line:       ns.line,
            end_line:   ns.end_line,
            rbs_file:   ns.rbs_file
          },

          documentation:   {
            docstring:  ns.docstring,
            examples:   ns.examples.map { |e| example_to_hash(e) },
            notes:      ns.notes,
            see_also:   ns.see_also.map { |s| see_to_hash(s) },
            deprecated: ns.deprecated,
            abstract:   ns.abstract,
            since:      ns.since,
            todo:       ns.todo,
            api:        ns.api
          },

          relationships:   {
            includes:         ns.includes,
            extends:          ns.extends,
            referenced_types: ns.referenced_types.map { |t| type_alias_to_hash(t) }
          },

          members:         {
            constants:    ns.constants.map { |c| constant_to_hash(c) },
            type_aliases: ns.type_aliases.map { |t| type_alias_to_hash(t) },
            ivars:        ns.ivars.map { |i| ivar_to_hash(i) },
            attributes:   ns.attributes.map { |a| attribute_to_hash(a) },
            methods:      ns.methods.map { |m| method_to_hash(m) }
          },

          private_methods: ns.private_methods.map { |m| method_summary(m) }
        }
      end

      # Convert DocumentModel structs to plain hashes for JSON serialization.

      def example_to_hash(e) = { name: e.name, code: e.code }

      def see_to_hash(s) = { target: s.target, text: s.text }

      def type_alias_to_hash(t)
        {
          name:        t.name,
          definition:  t.definition,
          description: t.description,
          namespace:   t.namespace
        }
      end

      def constant_to_hash(c)
        {
          name:        c.name,
          value:       c.value,
          type:        c.type,
          description: c.description
        }
      end

      def ivar_to_hash(i)
        {
          name:        i.name,
          type:        i.type,
          description: i.description
        }
      end

      def attribute_to_hash(a)
        {
          name:        a.name,
          type:        a.type,
          description: a.description,
          mode:        a.mode
        }
      end

      def param_to_hash(p)
        {
          name:        p.name,
          type:        p.type,
          description: p.description,
          default:     p.default,
          prefix:      p.prefix
        }
      end

      def option_to_hash(o)
        {
          param_name:  o.param_name,
          key:         o.key,
          type:        o.type,
          description: o.description
        }
      end

      def return_to_hash(r)
        return nil unless r

        { type: r.type, description: r.description }
      end

      def yield_to_hash(y)
        return nil unless y

        {
          description: y.description,
          params:      y.params.map { |p| param_to_hash(p) },
          return_type: y.return_type,
          return_desc: y.return_desc,
          block_type:  y.block_type
        }
      end

      def raise_to_hash(r) = { type: r.type, description: r.description }

      def overload_to_hash(o) = { signature: o.signature, description: o.description }

      def method_to_hash(m)
        {
          name:              m.name.to_s,
          scope:             m.scope,
          visibility:        m.visibility,
          signature:         m.signature,
          rbs_signature:     m.rbs_signature,

          docstring:         m.docstring,
          params:            m.params.map { |p| param_to_hash(p) },
          options:           m.options.map { |o| option_to_hash(o) },
          returns:           return_to_hash(m.returns),
          yields:            yield_to_hash(m.yields),
          raises:            m.raises.map { |r| raise_to_hash(r) },
          examples:          m.examples.map { |e| example_to_hash(e) },
          notes:             m.notes,
          see_also:          m.see_also.map { |s| see_to_hash(s) },

          api:               m.api,
          deprecated:        m.deprecated,
          abstract:          m.abstract,
          since:             m.since,
          todo:              m.todo,

          overloads:         m.overloads.map { |o| overload_to_hash(o) },

          source:            m.source,
          source_body_lines: m.source_body_lines,
          file:              m.file,
          line:              m.line
        }
      end

      def method_summary(m) = {
        name:  m.name.to_s,
        scope: m.scope,
        line:  m.line
      }

      def render_document(frontmatter, body_data)
        lines = []

        # YAML frontmatter
        lines << "---"
        lines << frontmatter.to_yaml.sub(/\A---\n/, "").chomp
        lines << "---"
        lines << ""

        # Title
        lines << "# #{frontmatter['title']}"
        lines << ""

        # Description if present
        if frontmatter["description"] && !frontmatter["description"].empty?
          lines << frontmatter["description"]
          lines << ""
        end

        # JSON data block
        lines << "## Semantic Data"
        lines << ""
        lines << "```json"
        lines << JSON.pretty_generate(body_data)
        lines << "```"
        lines << ""

        lines.join("\n")
      end

      def namespace_to_filename(path)
        stripped = @namespace_strip ? path.sub(/^#{Regexp.escape(@namespace_strip)}/, "") : path
        parts    = stripped.split("::")
        kebab    = parts.map { |p| to_kebab_case(p) }
        "#{kebab.join('/')}.md".sub(%r{^/}, "")
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
