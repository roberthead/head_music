# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::NoRests < HeadMusic::Style::Guideline
  def marks
    HeadMusic::Style::Mark.for_each(rests)
  end
end
