class HeadMusic::Content::Voice
  # The melodic view of a voice: its notes read as a sequence — the pitches they
  # sound, the span between the extremes, the note at or around a position, and
  # the consecutive pairs with their intervals and leaps. Built from an ordered
  # list of notes and memoizes the pairs, so callers sharing a MelodicLine see
  # the same pair objects.
  class MelodicLine
    attr_reader :notes

    def initialize(notes)
      @notes = notes
    end

    def pitches
      notes.map(&:pitch)
    end

    def highest_pitch
      pitches.max
    end

    def lowest_pitch
      pitches.min
    end

    def highest_notes
      notes_at_pitch(highest_pitch)
    end

    def lowest_notes
      notes_at_pitch(lowest_pitch)
    end

    def range
      HeadMusic::Analysis::DiatonicInterval.new(lowest_pitch, highest_pitch)
    end

    def note_at(position)
      notes.detect { |note| position.within_placement?(note) }
    end

    def notes_during(placement)
      notes.select { |note| note.during?(placement) }
    end

    def note_preceding(position)
      notes.reverse.find { |note| note.position < position }
    end

    def note_following(position)
      notes.detect { |note| note.position > position }
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

    private

    def notes_at_pitch(pitch)
      notes.select { |note| note.pitch == pitch }
    end
  end
end
