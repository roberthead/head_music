module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::AlwaysMove < HeadMusic::Style::Annotation
  MESSAGE = "Always move to a different note."

  def marks
    melodic_intervals.map.with_index do |interval, i|
      if interval.shorthand == 'PU'
        HeadMusic::Style::Mark.for_all(notes[i..i+1])
      end
    end.reject(&:nil?)
  end
end
