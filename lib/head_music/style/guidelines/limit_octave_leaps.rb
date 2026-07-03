# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline: Use a maximum of one octave leap.
# Configurable via the `maximum_leaps:` option.
class HeadMusic::Style::Guidelines::LimitOctaveLeaps < HeadMusic::Style::Annotation
  MAXIMUM_LEAPS = 1

  def marks
    return if octave_leaps.length <= maximum_leaps

    octave_leaps.map do |leap|
      HeadMusic::Style::Mark.for_all(leap.notes)
    end
  end

  def message
    "Use a maximum of #{maximum_leaps.humanize} octave #{(maximum_leaps == 1) ? "leap" : "leaps"}."
  end

  private

  def maximum_leaps
    options.fetch(:maximum_leaps) { self.class::MAXIMUM_LEAPS }
  end

  def octave_leaps
    melodic_note_pairs.select(&:octave?)
  end
end
