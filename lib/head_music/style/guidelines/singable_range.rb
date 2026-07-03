# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A voice shouldn't expend the range of a 10th.
# Configurable via the `maximum_range:` option (a diatonic interval number).
class HeadMusic::Style::Guidelines::SingableRange < HeadMusic::Style::Annotation
  MAXIMUM_RANGE = 10

  # Ordinals whose spoken form begins with a vowel sound take "an" instead of
  # "a" (an eighth, an eleventh, an eighteenth). Others in the singable range
  # take "a".
  VOWEL_SOUND_ORDINALS = [8, 11, 18].freeze

  def marks
    HeadMusic::Style::Mark.for_each(extremes, fitness: HeadMusic::PENALTY_FACTOR**overage) if overage.positive?
  end

  def message
    "Limit melodic range to #{indefinite_article} #{maximum_range.ordinalize}."
  end

  private

  def maximum_range
    options.fetch(:maximum_range) { self.class::MAXIMUM_RANGE }
  end

  def indefinite_article
    VOWEL_SOUND_ORDINALS.include?(maximum_range) ? "an" : "a"
  end

  def overage
    notes.any? ? [range.number - maximum_range, 0].max : 0
  end

  def extremes
    (highest_notes + lowest_notes).sort
  end
end
