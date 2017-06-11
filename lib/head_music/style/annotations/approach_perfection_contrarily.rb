module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::ApproachPerfectionContrarily < HeadMusic::Style::Annotation
  MESSAGE = 'Approach perfect consonances by contrary motion.'

  def marks
    motions_to_perfect_consonance_approached_directly.map do |bad_motion|
      HeadMusic::Style::Mark.for_all(bad_motion.notes)
    end
  end

  private

  def motions_to_perfect_consonance_approached_directly
    motions_to_perfect_consonance.select(&:direct?)
  end

  def motions_to_perfect_consonance
    motions.select do |motion|
      motion.second_harmonic_interval.perfect_consonance?
    end
  end
end
