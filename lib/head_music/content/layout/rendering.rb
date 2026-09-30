# A module for musical content
module HeadMusic::Content; end

class HeadMusic::Content::Layout
  # A layout written out in each notation: every flow it renders, realized
  # and passed to that notation's writer.
  class Rendering
    def initialize(layout)
      @layout = layout
    end

    # ABC has no book-title field, so a multi-tune layout's title is not
    # rendered; each tune carries its own T:.
    def to_abc
      realized_flows.map.with_index(1) do |flow, number|
        HeadMusic::Notation::ABC.render(flow, reference_number: number, transposed: @layout.transposed?)
      end.join("\n")
    end

    # A single flow renders exactly as the flow would on its own; several render
    # as successive \score blocks under one \header.
    def to_lilypond
      realized = realized_flows
      return HeadMusic::Notation::LilyPond.render(realized.first, **options) if realized.one?

      HeadMusic::Notation::LilyPond::BookWriter.new(realized, title: @layout.title, **options).to_s
    end

    def to_musicxml
      count = @layout.rendered_flows.length
      if count > 1
        raise HeadMusic::Notation::RenderError,
          "MusicXML holds one flow per document and this layout renders #{count}; use #to_musicxml_documents"
      end

      to_musicxml_documents.first
    end

    def to_musicxml_documents
      realized_flows.map.with_index(1) do |flow, number|
        HeadMusic::Notation::MusicXML.render(flow, **musicxml_options(number))
      end
    end

    private

    def realized_flows
      flows = @layout.rendered_flows
      if flows.empty?
        raise HeadMusic::Notation::RenderError, "the layout selects no flow that any selected player has a part in"
      end

      flows.map { |flow| @layout.realize(flow) }
    end

    # A document standing alone names only itself, which is what keeps a one-flow
    # layout byte-identical to the flow's own output.
    def musicxml_options(movement_number)
      return options if @layout.rendered_flows.one?

      options.merge(work_title: @layout.title, movement_number: movement_number)
    end

    def options
      {transposed: @layout.transposed?, arranger: arranger}
    end

    # The project's arrangers, joined as the composer is: this version's credit,
    # which is why a flow rendering on its own has none to print.
    def arranger
      names = @layout.project.credits.names(:arranger)
      names.join(", ") unless names.empty?
    end
  end
end
