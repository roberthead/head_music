# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that each middle bar contains exactly one whole note.
class HeadMusic::Style::Guidelines::OnePerBar < HeadMusic::Style::Guidelines::NoteCountPerBar
  COUNT = 1
  RHYTHMIC_VALUE = :whole
end
