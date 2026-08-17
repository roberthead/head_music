# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that the first bar contains quarter notes, with an optional quarter rest on beat one.
class HeadMusic::Style::Guidelines::FirstBarQuarterNotes < HeadMusic::Style::Guidelines::FirstBarEntry
  private

  def expected_rhythmic_value
    HeadMusic::Rudiment::RhythmicValue.get(:quarter)
  end
end
