# Key signatures are enharmonic when they represent the same set of altered pitch classes but with different spellings.
class HeadMusic::Rudiment::KeySignature::EnharmonicEquivalence < HeadMusic::Rudiment::EnharmonicEquivalence
  def self.subject_class
    HeadMusic::Rudiment::KeySignature
  end

  alias_method :key_signature, :subject

  def enharmonic_equivalent?(other)
    other = HeadMusic::Rudiment::KeySignature.get(other)

    key_signature.pitch_classes.map(&:to_i).sort == other.pitch_classes.map(&:to_i).sort &&
      key_signature.alterations.map(&:to_s).sort != other.alterations.map(&:to_s).sort
  end
end
