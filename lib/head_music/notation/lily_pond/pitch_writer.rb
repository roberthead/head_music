# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Converts a pitch into a LilyPond absolute-mode pitch token using the
  # default (Dutch) note names: letter, is/es alteration suffixes, and
  # octave marks relative to c' as middle C.
  class PitchWriter
    ALTERATION_SUFFIXES = {
      0 => "",
      1 => "is",
      -1 => "es",
      2 => "isis",
      -2 => "eses"
    }.freeze

    def self.token(pitch)
      pitch = HeadMusic::Rudiment::Pitch.get(pitch)
      letter = pitch.letter_name.to_s.downcase
      "#{letter}#{alteration_suffix(pitch.alteration_semitones)}#{octave_marks(pitch.register)}"
    end

    # Members that clash (see ChordClashes) force their accidentals with !,
    # written highest first, since LilyPond's bar memory keeps the
    # first-written member and engravers read the highest.
    def self.chord(pitches, forced: true)
      clashing = HeadMusic::Notation::ChordClashes.among(pitches)
      words = written_order(pitches).map { |pitch| "#{token(pitch)}#{"!" if forced && clashing.include?(pitch)}" }
      "<#{words.join(" ")}>"
    end

    def self.written_order(pitches)
      sorted = pitches.sort
      places = sorted.each_index.group_by { |index| HeadMusic::Notation::ChordClashes.place(sorted[index]) }
      places.each_value.with_object(sorted.dup) do |indexes, ordered|
        indexes.zip(indexes.reverse).each { |to, from| ordered[to] = sorted[from] }
      end
    end
    private_class_method :written_order

    # Public so KeyMapper spells its tonic with the same table.
    def self.alteration_suffix(semitones)
      ALTERATION_SUFFIXES.fetch(semitones.to_i) do
        raise RenderError, "no LilyPond spelling is known for an alteration of #{semitones} semitones"
      end
    end

    # The gem's middle C is register 4 and LilyPond's absolute-mode c' is
    # middle C (plain c is C3), so the mark count is register - 3.
    def self.octave_marks(register)
      marks = register - 3
      (marks >= 0) ? "'" * marks : "," * -marks
    end
    private_class_method :octave_marks
  end
end
