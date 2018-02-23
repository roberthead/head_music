# frozen_string_literal: true

# Module for Annotations.
module HeadMusic::Style::Annotations; end

# A counterpoint guideline
class HeadMusic::Style::Annotations::NoRests < HeadMusic::Style::Annotation
  MESSAGE = 'Place a note in each measure.'

  def marks
    HeadMusic::Style::Mark.for_each(rests)
  end
end
