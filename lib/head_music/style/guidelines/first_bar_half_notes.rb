# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that the first bar contains half notes, with an optional half rest on beat one.
class HeadMusic::Style::Guidelines::FirstBarHalfNotes < HeadMusic::Style::Guidelines::FirstBarEntry
  MESSAGE = "Begin the first bar with half notes, or enter after a half rest."

  private

  def expected_rhythmic_value
    HeadMusic::Rudiment::RhythmicValue.get(:half)
  end
end
