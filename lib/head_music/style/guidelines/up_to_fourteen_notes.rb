# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline: the cantus firmus should have at most fourteen notes.
class HeadMusic::Style::Guidelines::UpToFourteenNotes < HeadMusic::Style::Guidelines::MaximumNotes
  MAXIMUM_NOTES = 14
end
