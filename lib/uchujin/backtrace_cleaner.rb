# frozen_string_literal: true

module Uchujin
  module BacktraceCleaner
    module_function

    def normalize(backtrace)
      root = Rails.root.to_s
      gem_paths = Array(Gem.path)

      backtrace.map do |line|
        cleaned = line.to_s
        cleaned = cleaned.sub(root, "[PROJECT_ROOT]")
        gem_paths.each do |gp|
          cleaned = cleaned.sub(gp, "[GEM_ROOT]")
        end
        # Collapse absolute gem home variants
        cleaned = cleaned.gsub(%r{/gems/[^/]+/gems/}, "[GEM_ROOT]/")
        cleaned
      end
    end

    def application_only(backtrace)
      normalize(backtrace).select { |line| line.include?("[PROJECT_ROOT]") }
    end

    def with_source_context(backtrace, lines: Uchujin.configuration.source_context_lines)
      backtrace.first(40).map do |frame|
        { frame: frame, context: source_lines_for(frame, lines: lines) }
      end
    end

    def source_lines_for(frame, lines: 5)
      path, lineno = parse_frame(frame)
      return [] unless path && File.file?(path)

      file_lines = File.readlines(path)
      idx = lineno - 1
      start_i = [ idx - lines, 0 ].max
      end_i = [ idx + lines, file_lines.length - 1 ].min

      (start_i..end_i).map do |i|
        { number: i + 1, code: file_lines[i].to_s.chomp, highlight: i == idx }
      end
    rescue
      []
    end

    def parse_frame(frame)
      # Formats: /path/file.rb:12:in `method'  or [PROJECT_ROOT]/app/foo.rb:12
      if frame =~ %r{\A(.+):(\d+)}
        path = Regexp.last_match(1)
        path = path.sub("[PROJECT_ROOT]", Rails.root.to_s)
        [ path, Regexp.last_match(2).to_i ]
      end
    end
  end
end
