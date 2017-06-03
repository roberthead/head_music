module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::NoRests < HeadMusic::Style::Annotation
  def message
    "Use only notes."
  end

  def marks
    HeadMusic::Style::Mark.for_each(rests)
  end
end
