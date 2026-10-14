# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # A voice's hairpin starts and ends, paired into spans once the tune is
  # read. Marks arrive out of time order: a start on a tied note waits for
  # the note while an end on its later link is placed at once, and an
  # overlay's marks come after its bar's notes. So they are paired by
  # position, ends before starts at one position.
  #
  # As in abcm2ps, an end pairs with the latest open start of its kind, and
  # neither a level nor another start ends an open hairpin. Whatever pairs
  # into nothing, or into a hairpin the voice refuses, is dropped.
  class HairpinMarks
    Mark = Data.define(:position, :kind, :role)

    def initialize(voice)
      @voice = voice
      @marks = []
    end

    def record(position, decoration)
      role = (decoration.kind == :hairpin_end) ? :end : :start
      @marks << Mark.new(position, decoration.key.to_sym, role)
    end

    def add_spans
      open = Hash.new { |starts, kind| starts[kind] = [] }
      in_time_order.each do |mark|
        if mark.role == :start
          open[mark.kind] << mark.position
        else
          from = open[mark.kind].pop
          add_span(mark.kind, from, mark.position) if from
        end
      end
      @marks.clear
    end

    private

    def in_time_order
      @marks.each_with_index
        .sort_by { |mark, index| [mark.position, (mark.role == :end) ? 0 : 1, index] }
        .map(&:first)
    end

    def add_span(kind, from, to)
      @voice.add_span(kind, from: from, to: to)
    rescue ArgumentError
      nil
    end
  end
end
