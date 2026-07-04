# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A configurable guideline limiting melodic motion to singable intervals.
#
# Options:
# - ascending: permitted interval shorthands for ascending motion
# - descending: permitted interval shorthands for descending motion
# - message: the annotation message (defaults to listing the permitted intervals)
class HeadMusic::Style::Guidelines::SingableIntervals < HeadMusic::Style::Annotation
  DEFAULTS = {
    ascending: %w[P1 m2 M2 m3 M3 P4 P5 m6 P8].freeze,
    descending: %w[P1 m2 M2 m3 M3 P4 P5 m6 P8].freeze,
    message: nil
  }.freeze

  def message
    config[:message] || "Use only #{permitted_shorthands.join(", ")} in the melodic line."
  end

  def marks
    melodic_note_pairs.reject { |note_pair| permitted?(note_pair) }.map do |pair_with_unpermitted_interval|
      HeadMusic::Style::Mark.for_all(pair_with_unpermitted_interval.notes)
    end
  end

  private

  def config
    @config ||= DEFAULTS.merge(options)
  end

  def permitted_shorthands
    config[:ascending] | config[:descending]
  end

  def permitted?(note_pair)
    melodic_interval = note_pair.melodic_interval
    whitelist_for_interval(melodic_interval).include?(melodic_interval.shorthand)
  end

  def whitelist_for_interval(melodic_interval)
    melodic_interval.ascending? ? config[:ascending] : config[:descending]
  end
end
