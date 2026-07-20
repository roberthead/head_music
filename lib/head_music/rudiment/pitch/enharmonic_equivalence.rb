# An enharmonic equivalent pitch is the same frequency spelled differently, such as D# and Eb.
class HeadMusic::Rudiment::Pitch::EnharmonicEquivalence < HeadMusic::Rudiment::EnharmonicEquivalence
  def self.subject_class
    HeadMusic::Rudiment::Pitch
  end

  alias_method :pitch, :subject

  delegate :pitch_class, to: :pitch

  def enharmonic_equivalent?(other)
    other = HeadMusic::Rudiment::Pitch.get(other)
    pitch.midi_note_number == other.midi_note_number && pitch.spelling != other.spelling
  end
end
