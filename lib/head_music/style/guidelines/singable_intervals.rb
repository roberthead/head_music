# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::SingableIntervals < HeadMusic::Style::Annotation
  PERMITTED_ASCENDING = %w[P1 m2 M2 m3 M3 P4 P5 m6 P8].freeze
  PERMITTED_DESCENDING = %w[P1 m2 M2 m3 M3 P4 P5 m6 P8].freeze

  MESSAGE = "Use only P1, m2, M2, m3, M3, P4, P5, m6, P8 in the melodic line."

  def marks
    melodic_note_pairs.reject { |note_pair| permitted?(note_pair) }.map do |pair_with_unpermitted_interval|
      HeadMusic::Style::Mark.for_all(pair_with_unpermitted_interval.notes)
    end
  end

  private

  def permitted?(note_pair)
    melodic_interval = note_pair.melodic_interval
    whitelist_for_interval(melodic_interval).include?(melodic_interval.shorthand)
  end

  def whitelist_for_interval(melodic_interval)
    melodic_interval.ascending? ? PERMITTED_ASCENDING : PERMITTED_DESCENDING
  end
end
