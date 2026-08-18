module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # The line itself: the ends of it, the notes on either side of a note, and
  # how a note stands to the tonic.
  module MelodicContext
    def first_note
      notes.first
    end

    def last_note
      notes.last
    end

    protected

    def preceding_note(note)
      index = notes.index(note)
      notes[index - 1] if index&.positive?
    end

    # Indexing past the end returns nil, which is the answer for the last note.
    def following_note(note)
      index = notes.index(note)
      notes[index + 1] if index
    end

    # From the tonic below the note, so the interval is the one a singer hears
    # rather than a compound of it.
    def diatonic_interval_from_tonic(note)
      tonic_to_use = tonic_pitch
      tonic_to_use -= HeadMusic::Rudiment::ChromaticInterval.get(:perfect_octave) while tonic_to_use > note.pitch
      HeadMusic::Analysis::DiatonicInterval.new(tonic_to_use, note.pitch)
    end

    def starts_on_tonic?
      tonic_spelling == first_note.spelling
    end

    def tonic_pitch
      @tonic_pitch ||= HeadMusic::Rudiment::Pitch.get(tonic_spelling)
    end
  end
end
