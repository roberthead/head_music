# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Converts pitches into ABC note tokens, emitting the minimal accidental
  # marks required under the key signature and ABC's bar-persistent rules.
  #
  # A live PitchBuilder acts as an oracle: if an unmarked token would already
  # parse back to the target pitch, no accidental is written. Emitted tokens
  # are fed back through the oracle so its bar state matches what a parser
  # will accumulate when re-reading the output.
  class PitchWriter
    attr_reader :key_signature

    def initialize(key_signature)
      @key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature)
      @oracle = PitchBuilder.new(@key_signature)
    end

    # Returns the ABC note token for the pitch, without any duration multiplier.
    def token(pitch)
      pitch = HeadMusic::Rudiment::Pitch.get(pitch)
      letter = letter_token(pitch)
      octave_marks = octave_marks(pitch)
      return "#{letter}#{octave_marks}" if oracle.pitch(letter, octave_marks) == pitch

      marks = accidental_marks(pitch)
      commit_and_verify(pitch, letter, octave_marks, marks)
      "#{marks}#{letter}#{octave_marks}"
    end

    # In ABC, accidentals persist only to the end of the bar.
    def start_new_bar
      oracle.start_new_bar
    end

    private

    attr_reader :oracle

    def letter_token(pitch)
      letter = pitch.letter_name.to_s
      (pitch.register >= 5) ? letter.downcase : letter
    end

    def octave_marks(pitch)
      if pitch.register >= 5
        "'" * (pitch.register - 5)
      else
        "," * (4 - pitch.register)
      end
    end

    def accidental_marks(pitch)
      fragment = pitch.alteration&.ascii.to_s
      accidental_marks_by_fragment.fetch(fragment) do
        raise RenderError, "cannot express #{pitch} in ABC notation"
      end
    end

    def accidental_marks_by_fragment
      @accidental_marks_by_fragment ||= PitchBuilder::ACCIDENTAL_FRAGMENTS.invert
    end

    # Feeding the marked token through the oracle updates its bar state
    # exactly as a parser reading the output would — this call is load-bearing,
    # not just a verification; later unmarked notes depend on the state it writes.
    def commit_and_verify(pitch, letter, octave_marks, marks)
      return if oracle.pitch(letter, octave_marks, marks) == pitch

      raise RenderError, "cannot express #{pitch} in ABC notation"
    end
  end
end
