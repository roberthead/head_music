# Key signatures are enharmonic when they represent the same set of altered pitch classes but with different spellings.
class HeadMusic::Rudiment::KeySignature::EnharmonicEquivalence < HeadMusic::Rudiment::EnharmonicEquivalence
  def self.subject_class
    HeadMusic::Rudiment::KeySignature
  end

  alias_method :key_signature, :subject

  def enharmonic_equivalent?(other)
    other = HeadMusic::Rudiment::KeySignature.get(other)

    same_pitch_classes?(other) && different_spelling?(other)
  end

  private

  def same_pitch_classes?(other)
    sorted_pitch_class_numbers(key_signature) == sorted_pitch_class_numbers(other)
  end

  def different_spelling?(other)
    sorted_alteration_names(key_signature) != sorted_alteration_names(other)
  end

  def sorted_pitch_class_numbers(key_signature)
    key_signature.pitch_classes.map(&:to_i).sort
  end

  def sorted_alteration_names(key_signature)
    key_signature.alterations.map(&:to_s).sort
  end
end
