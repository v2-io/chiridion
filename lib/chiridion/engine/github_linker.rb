# frozen_string_literal: true

module Chiridion
  class Engine
    # Generates GitHub source links from file paths and line numbers.
    #
    # Parses git remote URL to extract org/repo, then constructs blob URLs
    # with line references for linking documentation back to source.
    class GithubLinker
      # @return [String, nil] GitHub base URL (e.g., "https://github.com/org/repo")
      attr_reader :base_url

      # @return [String] Git branch for source links
      attr_reader :branch

      # @param repo [String, nil] Explicit GitHub repo (e.g., "org/repo")
      # @param branch [String] Git branch for links
      # @param root [String] Project root for detecting git remote
      def initialize(repo: nil, branch: "main", root: Dir.pwd)
        @branch   = branch
        @base_url = repo ? "https://github.com/#{repo}" : extract_github_base_url(root)
      end

      # Generate a markdown link to a source location on GitHub.
      #
      # @param path [String] Project-relative file path
      # @param start_line [Integer] Starting line number
      # @param end_line [Integer, nil] Ending line number (optional)
      # @return [String] Markdown link or plain text if no GitHub remote
      def link(path, start_line, end_line = nil)
        text = format_text(path, start_line, end_line)
        return "`#{text}`" unless @base_url

        url = format_url(path, start_line, end_line)
        "[#{text}](#{url})"
      end

      # Generate just the URL (for frontmatter).
      #
      # @param path [String] Project-relative file path
      # @param start_line [Integer] Starting line number
      # @param end_line [Integer, nil] Ending line number (optional)
      # @return [String, nil] GitHub URL or nil if no GitHub remote
      def url(path, start_line, end_line = nil)
        return nil unless @base_url

        format_url(path, start_line, end_line)
      end

      private

      def format_text(path, start_line, end_line)
        if end_line && end_line != start_line
          "#{path}:#{start_line}-#{end_line}"
        else
          "#{path}:#{start_line}"
        end
      end

      def format_url(path, start_line, end_line)
        line_ref = if end_line && end_line != start_line
                     "L#{start_line}-L#{end_line}"
                   else
                     "L#{start_line}"
                   end
        "#{@base_url}/blob/#{@branch}/#{path}##{line_ref}"
      end

      # Pattern matching both HTTPS and SSH GitHub remote URLs:
      # - https://github.com/org/repo.git
      # - git@github.com:org/repo.git
      GITHUB_REMOTE_PATTERN = %r{
        (?:https://github\.com/|git@github\.com:)
        ([^/]+)/([^/]+?)(?:\.git)?$
      }x

      def extract_github_base_url(root)
        remote_url = `cd #{root} && git remote get-url origin 2>/dev/null`.strip
        return nil if remote_url.empty?

        match = remote_url.match(GITHUB_REMOTE_PATTERN)
        "https://github.com/#{match[1]}/#{match[2]}" if match
      end
    end
  end
end
