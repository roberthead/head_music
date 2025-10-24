# A module for music rudiments
module HeadMusic::Rudiment; end

# Quarter-comma meantone temperament
# Optimizes major thirds to be pure (5:4) at the expense of perfect fifths
class HeadMusic::Rudiment::Tuning::Meantone < HeadMusic::Rudiment::Tuning
  # Frequency ratios for intervals in quarter-comma meantone temperament
  # The defining characteristic is that major thirds are pure (5:4)
  # and the syntonic comma is distributed equally among the four fifths
  INTERVAL_RATIOS = {
    unison: Rational(1, 1),
    minor_second: 5.0**(1.0 / 4) / 2.0**(1.0 / 2),     # ~1.0697
    major_second: 5.0**(1.0 / 4),                       # ~1.1892 (fourth root of 5)
    minor_third: 5.0**(1.0 / 2) / 2.0**(1.0 / 2),      # ~1.5811
    major_third: Rational(5, 4),                        # Pure major third (1.25)
    perfect_fourth: 2.0**(1.0 / 2) / 5.0**(1.0 / 4),   # ~1.3375
    tritone: 5.0**(3.0 / 4) / 2.0**(1.0 / 2),          # ~1.6719
    perfect_fifth: Rational(3, 2),                      # ~1.4953 (slightly flat)
    minor_sixth: 2.0**(3.0 / 2) / 5.0**(1.0 / 4),      # ~1.6818
    major_sixth: 5.0**(3.0 / 4),                        # ~1.8877
    minor_seventh: 2.0**(3.0 / 2) / 5.0**(1.0 / 2),    # ~1.8877
    major_seventh: Rational(25, 16),                    # ~1.5625
    octave: Rational(2, 1)                              # Octave (2.0)
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

    # Get the meantone ratio for this interval
    ratio = ratio_for_interval(interval_from_tonal_center)

    # Calculate the frequency
    tonal_center_frequency * ratio
  end
end
