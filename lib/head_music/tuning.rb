# frozen_string_literal: true

# A tuning has a reference pitch and frequency and provides frequencies for all pitches
# The base class assumes equal temperament tuning. By default, A4 = 440.0 Hz
class HeadMusic::Tuning
  REFERENCE_FREQUENCY = 440.0
  REFERENCE_PITCH_NAME = 'A4'

  attr_reader :reference_pitch, :reference_frequency

  def initialize(reference_pitch: nil, reference_frequency: nil)
    @reference_pitch = reference_pitch || HeadMusic::Pitch.get(REFERENCE_PITCH_NAME)
    @reference_frequency = reference_frequency || REFERENCE_FREQUENCY
  end

  def frequency_for(pitch)
    pitch = HeadMusic::Pitch.get(pitch) unless pitch.is_a?(HeadMusic::Pitch)
    reference_frequency * (2**(1.0 / 12))**(pitch - reference_pitch).semitones
  end
end
