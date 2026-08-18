# A module for style analysis and guidelines.
module HeadMusic::Style; end

# Lookup facade for the guides in HeadMusic::Style::Guides. Never instantiated;
# .get returns a guide class or a Guides::Configured, either of which answers
# assess(voice), key, category, and display_name.
class HeadMusic::Style::Guide
  GUIDE_CLASSES = [
    HeadMusic::Style::Guides::FuxCantusFirmus,
    HeadMusic::Style::Guides::SalzerSchachterCantusFirmus,
    HeadMusic::Style::Guides::DiatonicMelody,
    HeadMusic::Style::Guides::FirstSpeciesMelody,
    HeadMusic::Style::Guides::FirstSpeciesHarmony,
    HeadMusic::Style::Guides::SecondSpeciesMelody,
    HeadMusic::Style::Guides::SecondSpeciesHarmony,
    HeadMusic::Style::Guides::ThirdSpeciesMelody,
    HeadMusic::Style::Guides::ThirdSpeciesHarmony,
    HeadMusic::Style::Guides::ThirdSpeciesTripleMeterMelody,
    HeadMusic::Style::Guides::ThirdSpeciesTripleMeterHarmony,
    HeadMusic::Style::Guides::FourthSpeciesMelody,
    HeadMusic::Style::Guides::FourthSpeciesHarmony,
    HeadMusic::Style::Guides::CombinedFirstSecondThirdSpeciesMelody,
    HeadMusic::Style::Guides::CombinedFirstSecondThirdSpeciesHarmony,
    HeadMusic::Style::Guides::FifthSpeciesMelody,
    HeadMusic::Style::Guides::FifthSpeciesHarmony
  ].freeze

  # Why the registry is an explicit list: no inherited hook or constant scan
  # can produce an entry that is an instance rather than a class.
  CONTOUR_CONFIGURATIONS = {
    "arch_contour_melody" => {contour: :arch, minimum_melodic_intervals: 2},
    "ascending_contour_melody" => {contour: :ascending, minimum_melodic_intervals: 1},
    "descending_contour_melody" => {contour: :descending, minimum_melodic_intervals: 1},
    "static_contour_melody" => {contour: :static},
    "valley_contour_melody" => {contour: :valley, minimum_melodic_intervals: 2},
    "wave_contour_melody" => {contour: :wave, minimum_melodic_intervals: 2}
  }.freeze

  REGISTRY = GUIDE_CLASSES.to_h { |guide_class| [guide_class.key, guide_class] }
    .merge(CONTOUR_CONFIGURATIONS.transform_values { |options|
      HeadMusic::Style::Guides::ContourMelody.with(**options)
    }).freeze

  ALL = REGISTRY.values.freeze

  # Resolves every entry at load, so nothing in the registry is written to
  # afterwards and concurrent lookups never race on the memo.
  ALL.each(&:guide_items)
  # A miss returns nil rather than falling back, unlike Tradition.get: a
  # substituted guide would grade a voice against the wrong ruleset.
  #
  # A plain hash lookup: HashKey.for would memoize per distinct argument and
  # these keys arrive from a consumer's database. The pass-through checks
  # assess_items because guidelines answer assess too, with other arguments.
  def self.get(key)
    return key if key.respond_to?(:assess_items)

    REGISTRY[key.to_s]
  end

  def self.get!(key)
    get(key) || raise(KeyError, "unknown style guide: #{key.inspect}")
  end

  # Not delegated to .get, which would answer true for any assess_items
  # responder -- leaving known? and key_for disagreeing about the same object.
  def self.known?(key)
    REGISTRY.key?(key.to_s) || !key_for(key).nil?
  end

  def self.all
    ALL
  end

  def self.keys
    REGISTRY.keys
  end

  def self.key_for(guide)
    REGISTRY.key(guide)
  end

  def self.display_name_for(key)
    I18n.translate(
      "#{key}.name",
      scope: "head_music.style.guides",
      default: key.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
    )
  end

  def self.instruction_for(key)
    HeadMusic::Style::Template.render("guides.#{key}.instruction")
  end

  # An unfillable template is invisible until someone reads it, so every string
  # is asked for here. Holds the keys whose plural forms the locale data lacks.
  PLURAL_GAPS = HeadMusic::Style::Template.verify!(ALL).freeze
end
