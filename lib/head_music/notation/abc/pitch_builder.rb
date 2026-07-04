# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Converts lexed ABC note data into pitches, applying the key signature
  # and ABC's bar-persistent accidental rules.
  class PitchBuilder
    # ABC accidental marks mapped to pitch-name fragments.
    # The natural sign maps to an empty fragment because a natural pitch
    # name carries no alteration symbol.
    ACCIDENTAL_FRAGMENTS = {
      "^" => "#",
      "^^" => "x",
      "_" => "b",
      "__" => "bb",
      "=" => ""
    }.freeze

    attr_reader :key_signature

    def initialize(key_signature)
      @key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature)
      start_new_bar
    end

    # letter: raw ABC letter preserving case ("A".."G" or "a".."g")
    # octave_marks: a string of "'" and "," characters (possibly empty or nil)
    # accidental_marks: nil, "^", "^^", "_", "__", or "="
    def pitch(letter, octave_marks = "", accidental_marks = nil)
      letter_name = letter.upcase
      octave = octave_for(letter, octave_marks)
      fragment = accidental_fragment(letter_name, octave, accidental_marks)
      name = "#{letter_name}#{fragment}#{octave}"
      HeadMusic::Rudiment::Pitch.from_name(name) ||
        raise(ParseError, "invalid pitch: #{name.inspect}")
    end

    # In ABC, accidentals persist only to the end of the bar.
    def start_new_bar
      @bar_accidentals = {}
    end

    private

    def octave_for(letter, octave_marks)
      base_octave = (letter == letter.upcase) ? 4 : 5
      marks = octave_marks.to_s
      base_octave + marks.count("'") - marks.count(",")
    end

    def accidental_fragment(letter_name, octave, accidental_marks)
      return explicit_fragment(letter_name, octave, accidental_marks) if present?(accidental_marks)

      @bar_accidentals.fetch([letter_name, octave]) { key_signature_fragment(letter_name) }
    end

    # An explicit accidental applies to later unmarked notes of the same
    # letter and octave until the next bar line.
    def explicit_fragment(letter_name, octave, accidental_marks)
      fragment = ACCIDENTAL_FRAGMENTS.fetch(accidental_marks) do
        raise ParseError, "invalid accidental marks: #{accidental_marks.inspect}"
      end
      @bar_accidentals[[letter_name, octave]] = fragment
    end

    def key_signature_fragment(letter_name)
      spelling = key_signature.alterations.find { |altered| altered.letter_name.to_s == letter_name }
      spelling ? spelling.alteration.to_s : ""
    end

    def present?(accidental_marks)
      !accidental_marks.to_s.empty?
    end
  end
end
