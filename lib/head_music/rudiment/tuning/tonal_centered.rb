# A module for music rudiments
module HeadMusic::Rudiment; end

# Mixin for tunings defined relative to a tonal center, defaulting that
# center to C4 when none is supplied.
module HeadMusic::Rudiment::Tuning::TonalCentered
  def initialize(reference_pitch: :a440, tonal_center: nil)
    super(reference_pitch: reference_pitch, tonal_center: tonal_center || "C4")
  end
end
