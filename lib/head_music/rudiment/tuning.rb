# A module for music rudiments
module HeadMusic::Rudiment; end

# A tuning has a reference pitch and frequency and provides frequencies for all pitches
# The base class assumes equal temperament tuning. By default, A4 = 440.0 Hz
class HeadMusic::Rudiment::Tuning
  attr_accessor :reference_pitch

  delegate :pitch, :frequency, to: :reference_pitch, prefix: true

  def initialize(reference_pitch: :a440)
    @reference_pitch = HeadMusic::Rudiment::ReferencePitch.get(reference_pitch)
  end

  def frequency_for(pitch)
    pitch = HeadMusic::Rudiment::Pitch.get(pitch)
    reference_pitch_frequency * (2**(1.0 / 12))**(pitch - reference_pitch.pitch).semitones
  end
end

# TODO: other tunings
