module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::NoRests < HeadMusic::Style::Annotation
  MESSAGE = "Place a note in each measure."

  def marks
    HeadMusic::Style::Mark.for_each(rests)
  end
end
