# Enharmonic equivalence occurs when two spellings refer to the same pitch class, such as D# and Eb.
class HeadMusic::Rudiment::Spelling::EnharmonicEquivalence < HeadMusic::Rudiment::EnharmonicEquivalence
  def self.subject_class
    HeadMusic::Rudiment::Spelling
  end

  alias_method :spelling, :subject

  def enharmonic_equivalent?(other)
    other = HeadMusic::Rudiment::Spelling.get(other)
    spelling != other && spelling.pitch_class_number == other.pitch_class_number
  end
end
