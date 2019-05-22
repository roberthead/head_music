# frozen_string_literal: true

# A tuning has a reference pitch and frequency and provides frequencies for all pitches
# The base class assumes equal temperament tuning. By default, A4 = 440.0 Hz
class HeadMusic::Tuning
  attr_accessor :reference_pitch

  delegate :pitch, :frequency, to: :reference_pitch, prefix: true

  def initialize(reference_pitch: nil)
    @reference_pitch = reference_pitch || HeadMusic::ReferencePitch.a440
  end

  def frequency_for(pitch)
    pitch = HeadMusic::Pitch.get(pitch) unless pitch.is_a?(HeadMusic::Pitch)
    reference_pitch_frequency * (2**(1.0 / 12))**(pitch - reference_pitch.pitch).semitones
  end
end

# TODO: other tunings
# Create website that hosts videos on theory and history, handy charts, etc.
# one of those charts can be a frequency table in various tunings
# maybe show pythagorean commas and such. or cents sharp or flat relative to either equal temperment or just intonation
