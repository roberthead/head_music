# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Renders several flows as one LilyPond document. Successive \score blocks at
  # the top level are already a book, so no \book wrapper is needed; one would
  # only buy the page-break control that engraving is out of scope for. Each
  # score is assembled by a Writer of its own, so a flow renders inside a book
  # exactly as it renders alone.
  class BookWriter
    attr_reader :flows, :title, :transposed, :arranger

    def initialize(flows, title: nil, transposed: false, arranger: nil)
      raise RenderError, "a LilyPond book holds at least one flow" if flows.empty?

      @flows = flows
      @title = title
      @transposed = transposed
      @arranger = arranger
    end

    def to_s
      document_lines.join("\n") + "\n"
    end

    private

    # Helper classes load in name order, so Writer's constants are read here
    # rather than at this class's load time.
    def indent
      Writer::INDENT
    end

    def document_lines
      [
        %(\\version "#{Writer::LILYPOND_VERSION}"),
        *header_lines,
        *flows.flat_map { |flow| ["", *Writer.new(flow, transposed: transposed).score_block(piece: flow.name)] }
      ]
    end

    def header_lines
      [
        "\\header {",
        title && %(#{indent}title = "#{StringText.escape(title)}"),
        composer && %(#{indent}composer = "#{StringText.escape(composer)}"),
        arranger && %(#{indent}arranger = "#{StringText.escape(arranger)}"),
        "}"
      ].compact
    end

    # A book whose movements name different composers stays silent rather than
    # crediting the first of them.
    def composer
      composers = flows.map(&:composer).uniq
      composers.first if composers.length == 1
    end
  end
end
