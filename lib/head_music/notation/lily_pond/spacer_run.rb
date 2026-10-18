# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Spacers from one offset in a bar to another, each mark on the first
  # spacer where it falls. Between marks where notes start, such as at
  # tuplet onsets, a multiplied spacer reaches what no note value does.
  class SpacerRun
    def initialize(bar_number, from, to, marks)
      @bar_number = bar_number
      @from = from
      @to = to
      @marks_by_offset = marks.group_by(&:offset)
    end

    def to_s
      [from, *marks_by_offset.keys.sort, to].uniq.each_cons(2).flat_map { |start, finish| spacers_between(start, finish) }.join(" ")
    end

    private

    attr_reader :bar_number, :from, :to, :marks_by_offset

    def spacers_between(start, finish)
      at_onsets = [start, finish].all? { |offset| marks_at(offset).all?(&:onset) }
      first, *later = spacers(finish - start, at_onsets) || raise_unreachable(marks_by_offset[finish] || marks_by_offset[start])
      ["#{first}#{marks_at(start).map(&:token).join}", *later]
    end

    def marks_at(offset)
      marks_by_offset.fetch(offset, [])
    end

    def spacers(fraction, multiplied)
      chain = HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)&.tied_chain&.map { |link| "s#{DurationWriter.token(link)}" }
      chain || (multiplied ? ["s1*#{fraction.numerator}/#{fraction.denominator}"] : nil)
    end

    def raise_unreachable(marks)
      subject = marks ? "the #{marks.first.label}" : "the dynamics in bar #{bar_number}"
      raise RenderError, "cannot place #{subject} in LilyPond output: no binary note value reaches it"
    end
  end
end
