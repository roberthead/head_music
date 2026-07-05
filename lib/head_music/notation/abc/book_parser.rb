# Interprets an ABC tune book — one or more tunes separated by blank
# lines, each beginning with an X: field — as an array of compositions.
#
# Parsing is all-or-nothing: any invalid tune raises, so callers never
# receive a partial array. Each tune is delegated to Parser with its
# book-relative start line, so errors point into the book.
class HeadMusic::Notation::ABC::BookParser
  Segment = Data.define(:text, :start_line)

  def initialize(book_string)
    @book_string = book_string.to_s
  end

  def compositions
    @compositions ||= parse_segments
  end

  private

  def parse_segments
    ensure_input_present
    segments = split_into_segments
    ensure_tunes_found(segments)
    segments.map do |segment|
      HeadMusic::Notation::ABC::Parser.new(segment.text, start_line: segment.start_line).composition
    end
  end

  def ensure_input_present
    return unless @book_string.strip.empty?

    raise HeadMusic::Notation::ABC::ParseError, "ABC input is blank"
  end

  def ensure_tunes_found(segments)
    return if segments.any?

    raise HeadMusic::Notation::ABC::ParseError, "No tunes found in ABC input"
  end

  # Groups lines into blank-line-separated paragraphs, dropping
  # paragraphs that contain only comments.
  def split_into_segments
    segments = []
    current_lines = nil
    current_start = nil
    @book_string.lines.each_with_index do |line, index|
      if line.strip.empty?
        segments << build_segment(current_lines, current_start) if current_lines
        current_lines = nil
        next
      end
      if current_lines.nil?
        current_lines = []
        current_start = index + 1
      end
      current_lines << line
    end
    segments << build_segment(current_lines, current_start) if current_lines
    segments.compact
  end

  def build_segment(lines, start_line)
    first_content_index = lines.find_index { |line| !line.strip.start_with?("%") }
    return nil unless first_content_index

    unless lines[first_content_index].strip.start_with?("X:")
      raise HeadMusic::Notation::ABC::ParseError.new(
        "Expected a tune to begin with an X: field",
        line_number: start_line + first_content_index,
        snippet: lines[first_content_index].strip[0, HeadMusic::Notation::ABC::BodyLexer::SNIPPET_LENGTH]
      )
    end
    Segment.new(text: lines.join, start_line: start_line)
  end
end
