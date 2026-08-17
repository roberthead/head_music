# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A configurable guideline limiting melodic motion to singable intervals.
#
# Options:
# - ascending: permitted interval shorthands for ascending motion
# - descending: permitted interval shorthands for descending motion
# - violation_key: names an alternative violation template
class HeadMusic::Style::Guidelines::SingableIntervals < HeadMusic::Style::Guideline
  # Traditional pedagogy permits the minor sixth ascending only.
  DEFAULTS = {
    ascending: %w[P1 m2 M2 m3 M3 P4 P5 m6 P8].freeze,
    descending: %w[P1 m2 M2 m3 M3 P4 P5 P8].freeze
  }.freeze

  def self.violation_key(config = {})
    config[:violation_key] || super()
  end

  # The permitted list is the message, and it is derivable from configuration
  # alone, so an item can preview it without a voice.
  def self.template_values(config)
    return {} if config[:violation_key]

    settings = DEFAULTS.merge(config)
    shorthands = settings[:ascending] | settings[:descending]
    {intervals: shorthands.map { |shorthand| describe(shorthand, settings) }.join(", ")}
  end

  def self.describe(shorthand, settings)
    both = settings[:ascending].include?(shorthand) && settings[:descending].include?(shorthand)
    return shorthand if both

    direction = settings[:ascending].include?(shorthand) ? :ascending : :descending
    HeadMusic::Style::Template.render("interval_directions.#{direction}", interval: shorthand)
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

  def permitted_descriptions
    (ascending_shorthands | descending_shorthands).map do |shorthand|
      describe_shorthand(shorthand)
    end
  end

  def describe_shorthand(shorthand)
    return shorthand if both_directions?(shorthand)

    direction = ascending_shorthands.include?(shorthand) ? :ascending : :descending
    HeadMusic::Style::Template.render("interval_directions.#{direction}", interval: shorthand)
  end

  def both_directions?(shorthand)
    ascending_shorthands.include?(shorthand) && descending_shorthands.include?(shorthand)
  end

  def permitted?(note_pair)
    melodic_interval = note_pair.melodic_interval
    whitelist_for_interval(melodic_interval).include?(melodic_interval.shorthand)
  end

  def whitelist_for_interval(melodic_interval)
    melodic_interval.ascending? ? ascending_shorthands : descending_shorthands
  end

  def ascending_shorthands
    config[:ascending]
  end

  def descending_shorthands
    config[:descending]
  end
end
