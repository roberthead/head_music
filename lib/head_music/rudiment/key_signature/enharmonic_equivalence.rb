# Key signatures are enharmonic when they represent the same set of altered pitch classes but with different spellings.
class HeadMusic::Rudiment::KeySignature::EnharmonicEquivalence
  attr_reader :key_signature

  def self.get(key_signature)
    key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature)
    @enharmonic_equivalences ||= {}
    @enharmonic_equivalences[key_signature.to_s] ||= new(key_signature)
  end

  def initialize(key_signature)
    @key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature)
  end

  def enharmonic_equivalent?(other)
    other = HeadMusic::Rudiment::KeySignature.get(other)

    key_signature.pitch_classes.map(&:to_i).sort == other.pitch_classes.map(&:to_i).sort &&
      key_signature.alterations.map(&:to_s).sort != other.alterations.map(&:to_s).sort
  end

  alias_method :enharmonic?, :enharmonic_equivalent?
  alias_method :equivalent?, :enharmonic_equivalent?

  private_class_method :new
end
