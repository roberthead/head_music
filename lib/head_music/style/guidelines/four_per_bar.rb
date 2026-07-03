# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that each middle bar contains exactly four quarter notes.
class HeadMusic::Style::Guidelines::FourPerBar < HeadMusic::Style::Guidelines::NoteCountPerBar
  COUNT = 4
  RHYTHMIC_VALUE = :quarter
end
