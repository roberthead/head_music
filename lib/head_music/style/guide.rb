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
    HeadMusic::Style::Guides::FirstThreeSpeciesMelody,
    HeadMusic::Style::Guides::FirstThreeSpeciesHarmony,
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

  LEAF_REGISTRY = GUIDE_CLASSES.to_h { |guide_class| [guide_class.key, guide_class] }
    .merge(CONTOUR_CONFIGURATIONS.transform_values { |options|
      HeadMusic::Style::Guides::ContourMelody.with(**options)
    }).freeze

  # A species is a melody guide and a harmony guide, and which two make up third
  # species is counterpoint pedagogy rather than a consumer's configuration.
  # Registered so a consumer asks for "third_species" and gets one grade back.
  COMPOSITE_MEMBERS = {
    "first_species" => %w[first_species_melody first_species_harmony],
    "second_species" => %w[second_species_melody second_species_harmony],
    "third_species" => %w[third_species_melody third_species_harmony],
    "third_species_triple_meter" => %w[third_species_triple_meter_melody third_species_triple_meter_harmony],
    "fourth_species" => %w[fourth_species_melody fourth_species_harmony],
    "fifth_species" => %w[fifth_species_melody fifth_species_harmony],
    "first_three_species" => %w[first_three_species_melody first_three_species_harmony]
  }.freeze

  # Two passes, because a composite names entries the first pass built. Merged
  # over LEAF_REGISTRY rather than over REGISTRY, which does not exist yet.
  #
  # fetch, so a member renamed in Guides takes the gem down on require rather
  # than leaving a species holding half a ruleset.
  REGISTRY = LEAF_REGISTRY.merge(
    COMPOSITE_MEMBERS.transform_values { |keys|
      HeadMusic::Style::Guides::CompositeGuide.new(keys.map { |key| LEAF_REGISTRY.fetch(key) })
    }
  ).freeze

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
