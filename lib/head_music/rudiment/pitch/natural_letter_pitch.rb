class HeadMusic::Rudiment::Pitch
  # The unaltered pitch of a letter name, in the register that puts it nearest a
  # given midi note number: the pitch a spelling of that number is measured from.
  #
  # A tritone is the tie-break. Any further and the same letter in the next
  # register is closer, so the alteration measured from here would be the larger
  # of the two ways to spell the note.
  class NaturalLetterPitch
    OCTAVE_SEMITONES = 12
    TRITONE_SEMITONES = 6

    attr_reader :number, :letter_name

    def self.get(number, letter_name)
      new(number, letter_name).pitch
    end

    def initialize(number, letter_name)
      @number = number.to_i
      @letter_name = HeadMusic::Rudiment::LetterName.get(letter_name)
    end

    def pitch
      @pitch ||= nearest_register_of(HeadMusic::Rudiment::Pitch.get(letter_name.pitch_class))
    end

    private

    def nearest_register_of(candidate)
      candidate += OCTAVE_SEMITONES while (number - candidate.to_i) >= TRITONE_SEMITONES
      candidate -= OCTAVE_SEMITONES while (number - candidate.to_i) <= -TRITONE_SEMITONES
      candidate
    end
  end
end
