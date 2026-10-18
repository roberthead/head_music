# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # The hairpin marks of one context, paired as LilyPond's dynamic
  # engraver pairs them: at each moment, any dynamic (a level, an accent,
  # a hairpin start, or \!) ends the open hairpin, and only then does the
  # last start written there open a new one, so \mf\< and \<\mf read alike.
  # An unterminated hairpin, a stray end, and a hairpin its owner refuses
  # are dropped.
  class HairpinMarks
    def initialize
      @marks = []
    end

    def add(position, marks)
      ends = (marks.level || marks.note_dynamic) ? [:end] : []
      (ends + marks.hairpin_marks).each { |mark| @marks << [position, mark] }
    end

    # LilyPond draws a hairpin ending after all the written time, spacers
    # included, to the final barline, which follows a short final bar where
    # its time stops.
    def pair(owners, written_end:, final_barline:)
      open = nil
      @marks.group_by(&:first).sort_by(&:first).each do |position, group|
        to = (position == written_end) ? final_barline : position
        owners.each { |owner| add_span(owner, *open, to) } if open
        start = group.map(&:last).reverse.find { |mark| mark != :end }
        open = start && [start, position]
      end
    end

    private

    def add_span(owner, kind, from, to)
      owner.add_span(kind, from: from, to: to)
    rescue ArgumentError
      nil
    end
  end
end
