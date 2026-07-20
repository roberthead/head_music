class HeadMusic::Content::Voice
  # The melodic view of a voice: its notes read as the sequence of consecutive
  # pairs, the interval spanned by each pair, and the leaps among them. Built
  # from an ordered list of notes and memoizes the pairs, so callers sharing a
  # MelodicLine see the same pair objects.
  class MelodicLine
    attr_reader :notes

    def initialize(notes)
      @notes = notes
    end

    def melodic_note_pairs
      @melodic_note_pairs ||= notes.each_cons(2).map do |first_note, second_note|
        MelodicNotePair.new(first_note, second_note)
      end
    end

    def melodic_intervals
      @melodic_intervals ||=
        melodic_note_pairs.map { |note_pair| HeadMusic::Analysis::MelodicInterval.new(*note_pair.notes) }
    end

    def leaps
      melodic_note_pairs.select(&:leap?)
    end

    def large_leaps
      melodic_note_pairs.select(&:large_leap?)
    end
  end
end
