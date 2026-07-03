# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that each middle bar contains exactly three quarter notes.
class HeadMusic::Style::Guidelines::ThreePerBar < HeadMusic::Style::Guidelines::NoteCountPerBar
  COUNT = 3
  RHYTHMIC_VALUE = :quarter
end
