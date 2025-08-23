# A module for music rudiments
module HeadMusic::Rudiment; end

# Abstract base class representing a tonal context (system of pitches with a tonal center)
class HeadMusic::Rudiment::TonalContext < HeadMusic::Rudiment::Base
  attr_reader :tonic_spelling

  def initialize(tonic_spelling)
    @tonic_spelling = HeadMusic::Rudiment::Spelling.get(tonic_spelling)
  end

  def tonic_pitch(octave = 4)
    HeadMusic::Rudiment::Pitch.get("#{tonic_spelling}#{octave}")
  end

  def scale
    raise NotImplementedError, "Subclasses must implement #scale"
  end

  def pitches(octave = nil)
    scale.pitches(direction: :ascending, octaves: 1)
  end

  def pitch_classes
    scale.pitch_classes
  end

  def spellings
    scale.spellings
  end

  def key_signature
    raise NotImplementedError, "Subclasses must implement #key_signature"
  end
end
