# A module for music rudiments
module HeadMusic::Rudiment; end

# Abstract class representing a diatonic tonal context (7-note scale system)
class HeadMusic::Rudiment::DiatonicContext < HeadMusic::Rudiment::TonalContext
  def scale_type
    raise AbstractMethodError, "Subclasses must implement #scale_type"
  end

  def scale
    @scale ||= HeadMusic::Rudiment::Scale.get(tonic_spelling, scale_type)
  end

  def key_signature
    @key_signature ||= HeadMusic::Rudiment::KeySignature.from_scale(scale)
  end

  def relative
    raise AbstractMethodError, "Subclasses must implement #relative"
  end

  def parallel
    raise AbstractMethodError, "Subclasses must implement #parallel"
  end
end
