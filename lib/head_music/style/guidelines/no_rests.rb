# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::NoRests < HeadMusic::Style::Guideline
  MESSAGE = "Place a note in each measure."

  def marks
    HeadMusic::Style::Mark.for_each(rests)
  end
end
