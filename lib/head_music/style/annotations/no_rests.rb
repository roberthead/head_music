module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::NoRests < HeadMusic::Style::Annotation
  MESSAGE = "Use only notes."

  def marks
    HeadMusic::Style::Mark.for_each(rests)
  end
end
