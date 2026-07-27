# A module for music rudiments
module HeadMusic::Rudiment; end

# An Alteration is a symbol that modifies pitch, such as a sharp, flat, or natural.
# In French, sharps and flats in the key signature are called "altérations".
class HeadMusic::Rudiment::Alteration < HeadMusic::Rudiment::Base
  include Comparable
  include HeadMusic::Named

  attr_reader :identifier, :semitones, :musical_symbols

  delegate :ascii, :unicode, :html_entity, to: :musical_symbol

  ALTERATION_RECORDS =
    YAML.load_file(File.expand_path("alterations.yml", __dir__), symbolize_names: true)[:alterations].freeze

  ALTERATION_IDENTIFIERS = ALTERATION_RECORDS.keys.freeze
  # Sorted longest-first because Regexp.union alternates in array order rather than by
  # longest match. Without it, "bb" would match the single-flat branch and leave a
  # stray "b" behind, half-converting a double. Ordering among equal-length symbols is
  # unspecified and does not matter: equal-length strings cannot prefix one another.
  SYMBOLS = ALTERATION_RECORDS
    .map { |key, attributes| attributes[:symbols].map { |symbol| [symbol[:unicode], symbol[:ascii]] } }
    .flatten.reject { |s| s.nil? || s.empty? }.uniq
    .sort_by { |symbol| -symbol.length }
    .freeze
  PATTERN = Regexp.union(SYMBOLS)
  MATCHER = PATTERN

  def self.all
    @all ||= ALTERATION_RECORDS.map { |key, attributes| new(key, attributes) }
  end

  def self.symbols
    SYMBOLS
  end

  def self.symbol?(candidate)
    SYMBOLS.include?(candidate)
  end

  def self.get(identifier)
    return identifier if identifier.is_a?(HeadMusic::Rudiment::Alteration)

    all.detect do |alteration|
      alteration.representations.include?(identifier)
    end
  end

  def self.by(key, value)
    all.detect do |alteration|
      alteration.send(key) == value if %i[semitones].include?(key.to_sym)
    end
  end

  def self.get_by_name(name)
    all.detect { |alteration| alteration.name == name.to_s }
  end

  def name(locale_code: I18n.locale)
    super || identifier.to_s.tr("_", " ")
  end

  # Spans every symbol record, not just the primary one, so that an alternate ASCII
  # spelling like "##" resolves through .get. Memoized per locale because .get runs on
  # every parse and walks this list for each alteration, and #name is locale-dependent.
  def representations(locale_code: I18n.locale)
    @representations ||= {}
    @representations[locale_code] ||=
      ([identifier, identifier.to_s, name(locale_code: locale_code)] +
        musical_symbols.flat_map { |symbol| [symbol.ascii, symbol.unicode, symbol.html_entity] })
        .uniq
        .reject { |representation| representation.to_s.strip == "" }
  end

  ALTERATION_RECORDS.keys.each do |key|
    define_method(:"#{key}?") { identifier == key }
  end

  def to_s
    unicode
  end

  def <=>(other)
    other = HeadMusic::Rudiment::Alteration.get(other)
    semitones <=> other.semitones
  end

  def musical_symbol
    musical_symbols.first
  end

  private

  def initialize(key, attributes)
    @identifier = key
    @semitones = attributes[:semitones]
    initialize_musical_symbols(attributes[:symbols])
    initialize_localized_names
  end

  def initialize_localized_names
    # Initialize default English names
    ensure_localized_name(name: identifier.to_s.tr("_", " "), locale_code: :en)
    # Additional localized names will be loaded from locale files
  end

  def initialize_musical_symbols(list)
    @musical_symbols = (list || []).map do |record|
      HeadMusic::Notation::MusicalSymbol.new(
        unicode: record[:unicode],
        ascii: record[:ascii],
        html_entity: record[:html_entity]
      )
    end
  end

  private_class_method :new
end
