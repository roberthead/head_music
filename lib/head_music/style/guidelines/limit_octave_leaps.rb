# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline: Use a maximum of one octave leap.
class HeadMusic::Style::Guidelines::LimitOctaveLeaps < HeadMusic::Style::Annotation
  MESSAGE = "Use a maximum of one octave leap."

  def marks
    return if octave_leaps.length <= 1

    octave_leaps.map do |leap|
      HeadMusic::Style::Mark.for_all(leap.notes)
    end
  end

  private

  def octave_leaps
    melodic_note_pairs.select(&:octave?)
  end
end
