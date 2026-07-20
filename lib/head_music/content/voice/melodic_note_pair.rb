class HeadMusic::Content::Voice
  # A pair of consecutive notes in a melodic line, used to analyze intervals and leaps.
  class MelodicNotePair
    attr_reader :first_note, :second_note

    delegate(
      :octave?, :unison?,
      :perfect?,
      :step?, :leap?, :large_leap?,
      :ascending?, :descending?, :repetition?,
      :spans?,
      :spells_consonant_triad_with?,
      to: :melodic_interval
    )

    def initialize(first_note, second_note)
      @first_note = first_note
      @second_note = second_note
    end

    def notes
      @notes ||= [first_note, second_note]
    end

    def pitches
      @pitches ||= notes.map(&:pitch)
    end

    def melodic_interval
      @melodic_interval ||= HeadMusic::Analysis::MelodicInterval.new(*notes)
    end
  end
end
