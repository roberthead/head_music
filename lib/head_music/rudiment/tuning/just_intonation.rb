# A module for music rudiments
module HeadMusic::Rudiment; end

# Just Intonation tuning system based on whole number frequency ratios
class HeadMusic::Rudiment::Tuning::JustIntonation < HeadMusic::Rudiment::Tuning
  # Frequency ratios for intervals in just intonation (relative to tonic)
  # Based on the major scale with pure intervals
  INTERVAL_RATIOS = {
    unison: Rational(1, 1),
    minor_second: Rational(16, 15),
    major_second: Rational(9, 8),
    minor_third: Rational(6, 5),
    major_third: Rational(5, 4),
    perfect_fourth: Rational(4, 3),
    tritone: Rational(45, 32),
    perfect_fifth: Rational(3, 2),
    minor_sixth: Rational(8, 5),
    major_sixth: Rational(5, 3),
    minor_seventh: Rational(16, 9),
    major_seventh: Rational(15, 8),
    octave: Rational(2, 1)
  }.freeze

  attr_reader :tonal_center

  def initialize(reference_pitch: :a440, tonal_center: nil)
    super
    @tonal_center = HeadMusic::Rudiment::Pitch.get(tonal_center || "C4")
  end

  def frequency_for(pitch)
    pitch = HeadMusic::Rudiment::Pitch.get(pitch)

    # Calculate the frequency of the tonal center using equal temperament from reference pitch
    tonal_center_frequency = calculate_tonal_center_frequency

    # Calculate the interval from the tonal center to the requested pitch
    interval_from_tonal_center = (pitch - tonal_center).semitones

    # Get the just intonation ratio for this interval
    ratio = ratio_for_interval(interval_from_tonal_center)

    # Calculate the frequency
    tonal_center_frequency * ratio
  end
end
