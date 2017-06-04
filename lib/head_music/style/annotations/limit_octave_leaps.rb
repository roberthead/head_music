module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::LimitOctaveLeaps < HeadMusic::Style::Annotation
  def message
    "Limit one octave skips to one (or none)."
  end

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
