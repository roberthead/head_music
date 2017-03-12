module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::NoRests < HeadMusic::Style::Annotation
  def message
    "Use only notes."
  end

  def marks
    rests.map { |rest| HeadMusic::Style::Mark.for(rest) }
  end
end
