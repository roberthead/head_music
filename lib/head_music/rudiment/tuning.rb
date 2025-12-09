# A module for music rudiments
module HeadMusic::Rudiment; end

# A tuning has a reference pitch and frequency and provides frequencies for all pitches
# The base class assumes equal temperament tuning. By default, A4 = 440.0 Hz
class HeadMusic::Rudiment::Tuning < HeadMusic::Rudiment::Base
  attr_accessor :reference_pitch

  delegate :pitch, :frequency, to: :reference_pitch, prefix: true

  def self.get(tuning_type = :equal_temperament, **options)
    case tuning_type.to_s.downcase
    when "just_intonation", "just", "ji"
      HeadMusic::Rudiment::Tuning::JustIntonation.new(**options)
    when "pythagorean", "pythag"
      HeadMusic::Rudiment::Tuning::Pythagorean.new(**options)
    when "meantone", "quarter_comma_meantone", "1/4_comma"
      HeadMusic::Rudiment::Tuning::Meantone.new(**options)
    when "equal_temperament", "equal", "et", "12tet"
      new(**options)
    else
      new(**options)
    end
  end

  def initialize(reference_pitch: :a440, tonal_center: nil)
    @reference_pitch = HeadMusic::Rudiment::ReferencePitch.get(reference_pitch)
    @tonal_center = tonal_center
  end

  def frequency_for(pitch)
    pitch = HeadMusic::Rudiment::Pitch.get(pitch)
    reference_pitch_frequency * (2**(1.0 / 12))**(pitch - reference_pitch.pitch).semitones
  end

  private

  def calculate_tonal_center_frequency
    # Use equal temperament to get the tonal center frequency from the reference pitch
    interval_to_tonal_center = (tonal_center - reference_pitch.pitch).semitones
    reference_pitch_frequency * (2**(interval_to_tonal_center / 12.0))
  end

  def ratio_for_interval(semitones)
    # Handle octaves
    octaves = semitones / 12
    interval_within_octave = semitones % 12

    # Get the base ratio from the subclass's INTERVAL_RATIOS constant
    base_ratio = self.class::INTERVAL_RATIOS[self.class::INTERVAL_RATIOS.keys[interval_within_octave]]

    # Apply octave adjustments
    base_ratio * (2**octaves)
  end
end
