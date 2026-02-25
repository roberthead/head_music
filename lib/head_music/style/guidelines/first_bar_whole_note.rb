# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that the first bar contains a whole note.
class HeadMusic::Style::Guidelines::FirstBarWholeNote < HeadMusic::Style::Guidelines::FirstBarEntry
  MESSAGE = "Begin with a whole note in the first bar."

  private

  def expected_rhythmic_value
    HeadMusic::Rudiment::RhythmicValue.get(:whole)
  end
end
