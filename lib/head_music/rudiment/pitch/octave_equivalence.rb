# Octave equivalence is the functional equivalence of pitches with the same spelling separated by one or more octaves.
class HeadMusic::Rudiment::Pitch::OctaveEquivalence
  def self.get(pitch)
    @octave_equivalences ||= {}
    @octave_equivalences[pitch.to_s] ||= new(pitch)
  end

  attr_reader :pitch

  def initialize(pitch)
    @pitch = pitch
  end

  def octave_equivalent?(other)
    other = HeadMusic::Rudiment::Pitch.get(other)
    pitch.spelling == other.spelling && pitch.register != other.register
  end

  alias_method :equivalent?, :octave_equivalent?

  private_class_method :new
end
