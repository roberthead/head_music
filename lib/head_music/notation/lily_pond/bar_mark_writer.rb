# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Writes a bar's marks: the rehearsal mark and signs that open it, and the
  # Fine, To Coda, jump, and barline that close it. The last bar closes with
  # a final barline unless it has a style of its own. The bar types come from
  # the BarMarkReader's table, so whatever is written reads back as itself.
  #
  # LilyPond warns about music after \fine, so a Fine before the last bar,
  # as in a D.C. al Fine, is written as a \textEndMark. It also keeps only one
  # \jump per bar, so a To Coda beside a jump is one too. LilyPond prints a
  # \textEndMark once per voice that has it, so only the lead voice does.
  # A segno and a coda sign cannot share a bar as marks either, so beside a
  # segno the coda sign is a \textMark of its glyph, in the lead voice.
  module BarMarkWriter
    module_function

    def opening_tokens(bar, lead: true)
      [
        bar.rehearsal_mark && %(\\mark "#{StringText.escape(bar.rehearsal_mark)}"),
        ("\\segnoMark 1" if bar.segno?),
        coda_token(bar, lead)
      ].compact
    end

    def coda_token(bar, lead)
      return unless bar.coda?
      return "\\codaMark 1" unless bar.segno?

      lead ? %(\\textMark \\markup \\musicglyph "#{BarMarkReader::SIGN_GLYPHS.key(:coda)}") : nil
    end

    def closing_tokens(bar, last: false, lead: true)
      [
        fine_token(bar, last, lead),
        to_coda_token(bar, lead),
        bar.jump && %(\\jump "#{bar.jump}"),
        barline_token(bar, last)
      ].compact
    end

    def fine_token(bar, last, lead)
      return unless bar.fine?
      return "\\fine" if last

      text_end_mark(BarMarkReader::FINE, lead)
    end

    def to_coda_token(bar, lead)
      return unless bar.to_coda?
      return %(\\jump "#{BarMarkReader::TO_CODA}") unless bar.jump

      text_end_mark(BarMarkReader::TO_CODA, lead)
    end

    def text_end_mark(text, lead)
      lead ? %(\\textEndMark "#{text}") : nil
    end

    def barline_token(bar, last)
      style = (last && bar.barline == :regular) ? :final : bar.barline
      bar_type = BarMarkReader::BARLINES_BY_TYPE.key(style)
      bar_type && %(\\bar "#{bar_type}")
    end
  end
end
