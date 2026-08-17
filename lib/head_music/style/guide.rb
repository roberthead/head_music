# A module for style analysis and guidelines.
module HeadMusic::Style; end

# Lookup facade for the guides in HeadMusic::Style::Guides. A class with a
# .get factory, matching Tradition and the gem's other .get definers -- no
# module in the gem defines .get. Never instantiated; .get returns a guide
# class or a Guides::Configured, either of which answers analyze(voice), key,
# category, and display_name.
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

  # The six preserved contour keys, literal and greppable. This table is the
  # reason the registry is an explicit list: no `inherited` hook or constant
  # scan can produce a registry entry that is an instance rather than a class.
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

  # A load-time check that every entry resolves. The configured entries already
  # resolved as they were built -- Configured does that in its constructor, so
  # nothing in the registry is written to after load and concurrent lookups
  # never race on the memo -- which leaves this reading the classes' constants.
  ALL.each(&:guide_items)

  # A miss returns nil rather than falling back, unlike Tradition.get: a
  # substituted tradition changes a consonance default, but a substituted
  # guide would silently grade a voice against the wrong ruleset.
  #
  # Deliberately a plain hash lookup. Utilities::HashKey.for would memoize an
  # entry per distinct argument, and these keys arrive from a consumer's
  # database; const_get would traverse namespaces and raise NameError on an
  # invalid name, violating nil-on-miss.
  def self.get(key)
    return key if key.respond_to?(:analyze)

    REGISTRY[key.to_s]
  end

  def self.get!(key)
    get(key) || raise(KeyError, "unknown style guide: #{key.inspect}")
  end

  # Asks whether the registry knows this, not whether it quacks like a guide.
  # Delegating to .get would answer true for any analyze-responder, including an
  # ad-hoc configuration whose key_for is nil -- so known? and key_for would
  # disagree about the same object.
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
      key,
      scope: "head_music.style.guides",
      default: key.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
    )
  end
end
