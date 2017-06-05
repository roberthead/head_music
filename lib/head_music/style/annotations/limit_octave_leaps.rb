module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::LimitOctaveLeaps < HeadMusic::Style::Annotation
  MESSAGE = "Use a maximum of one octave skip."

  def marks
    if octave_leaps.length > 1
      octave_leaps.map do |leap|
        HeadMusic::Style::Mark.for_all(leap.notes)
      end
    end
  end

  private

  def octave_leaps
    melodic_intervals.select(&:octave?)
  end
end
