# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that each middle bar contains exactly two half notes.
class HeadMusic::Style::Guidelines::TwoPerBar < HeadMusic::Style::Guidelines::NoteCountPerBar
  COUNT = 2
  RHYTHMIC_VALUE = :half
end
