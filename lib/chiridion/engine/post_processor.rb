# frozen_string_literal: true

module Chiridion
  class Engine
    # Post-processes rendered markdown for consistent formatting.
    #
    # Handles normalization that's easier to do as a final pass rather than
    # trying to get perfect output from templates. May grow into fuller
    # linting/validation over time.
    #
    # Current normalizations:
    # - Collapse multiple consecutive newlines to single newlines
    # - Ensure 2 newlines before horizontal rules (---)
    # - Preserve frontmatter formatting
    class PostProcessor
      # Normalize markdown content.
      #
      # @param content [String] Raw markdown content
      # @return [String] Normalized content
      def self.process(content)
        new.process(content)
      end

      # @param content [String] Raw markdown content
      # @return [String] Normalized content
      def process(content)
        # Split off frontmatter to preserve it exactly
        frontmatter, body = split_frontmatter(content)

        # Normalize the body
        normalized = normalize_newlines(body)

        # Reassemble
        frontmatter ? "#{frontmatter}\n\n#{normalized}" : normalized
      end

      private

      # Split YAML frontmatter from body content.
      #
      # @param content [String] Full markdown content
      # @return [Array(String, String), Array(nil, String)] [frontmatter, body] or [nil, content]
      def split_frontmatter(content)
        return [nil, content] unless content.start_with?("---")

        # Find closing ---
        lines = content.lines
        closing_idx = lines[1..].index { |l| l.strip == "---" }
        return [nil, content] unless closing_idx

        # closing_idx is relative to lines[1..], so actual index is closing_idx + 1
        fm_end = closing_idx + 2 # +1 for 0-index, +1 for the closing line itself
        frontmatter = lines[0...fm_end].join.strip
        body = lines[fm_end..].join

        [frontmatter, body]
      end

      # Normalize newlines in body content.
      #
      # Rules (applied in order):
      # 1. Collapse runs of 3+ newlines to exactly 2 (one blank line)
      # 2. Ensure 2 newlines before horizontal rules (---)
      # 3. Remove blank lines after horizontal rules (---)
      # 4. Remove blank lines after headers (# ## ### ####)
      #
      # @param body [String] Body content (no frontmatter)
      # @return [String] Normalized body
      def normalize_newlines(body)
        # Step 1: Collapse 3+ newlines to exactly 2
        result = body.gsub(/\n{3,}/, "\n\n")

        # Step 2: Ensure 2 newlines before horizontal rules
        result = result.gsub(/\n(---)/, "\n\n\\1")

        # Step 3: Remove blank lines after horizontal rules
        result = result.gsub(/^(---)\n+/, "\\1\n")

        # Step 4: Remove blank lines after headers
        result = result.gsub(/^(\#{1,6}\s+.+)\n+/, "\\1\n")

        result.strip
      end
    end
  end
end
