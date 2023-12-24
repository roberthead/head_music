# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::AlwaysMove < HeadMusic::Style::Annotation
  MESSAGE = "Always move to a different note."

  def marks
    melodic_intervals
      .select { |interval| interval.perfect? && interval.unison? }
      .map { |interval| HeadMusic::Style::Mark.for_all(interval.notes) }
  end
end
