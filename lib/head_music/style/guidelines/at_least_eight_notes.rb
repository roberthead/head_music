# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline: the cantus firmus should have at least eight notes.
class HeadMusic::Style::Guidelines::AtLeastEightNotes < HeadMusic::Style::Guidelines::MinimumNotes
  MINIMUM_NOTES = 8
end
