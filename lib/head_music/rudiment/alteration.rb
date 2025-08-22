require "head_music/rudiment/musical_symbol"

# A module for music rudiments
module HeadMusic::Rudiment; end

# An Alteration is a symbol that modifies pitch, such as a sharp, flat, or natural.
# In French, sharps and flats in the key signature are called "altérations".
class HeadMusic::Rudiment::Alteration < HeadMusic::Rudiment::Base
  include Comparable
  include HeadMusic::Named

  attr_reader :identifier, :cents, :musical_symbols

  delegate :ascii, :unicode, :html_entity, to: :musical_symbol

  ALTERATION_RECORDS = [
    {
      identifier: :sharp, cents: 100,
      symbols: [{ascii: "#", unicode: "♯", html_entity: "&#9839;"}]
    },
    {
      identifier: :flat, cents: -100,
      symbols: [{ascii: "b", unicode: "♭", html_entity: "&#9837;"}]
    },
    {
      identifier: :natural, cents: 0,
      symbols: [{ascii: "", unicode: "♮", html_entity: "&#9838;"}]
    },
    {
      identifier: :double_sharp, cents: 200,
      symbols: [{ascii: "x", unicode: "𝄪", html_entity: "&#119082;"}]
    },
    {
      identifier: :double_flat, cents: -200,
      symbols: [{ascii: "bb", unicode: "𝄫", html_entity: "&#119083;"}]
    }
  ].freeze

  ALTERATION_IDENTIFIERS = ALTERATION_RECORDS.map { |attributes| attributes[:identifier] }.freeze
  SYMBOLS = ALTERATION_RECORDS.map { |attributes| attributes[:symbols].map { |symbol| [symbol[:unicode], symbol[:ascii]] } }.flatten.freeze
  PATTERN = Regexp.union(SYMBOLS.reject { |s| s.nil? || s.empty? })
  MATCHER = PATTERN

  def self.all
    ALTERATION_RECORDS.map { |attributes| new(attributes) }
  end

  def self.symbols
    @symbols ||= all.map { |alteration| [alteration.ascii, alteration.unicode] }.flatten.reject { |s| s.nil? || s.empty? }
  end

  def self.symbol?(candidate)
    SYMBOLS.include?(candidate)
  end

  def self.get(identifier)
    return identifier if identifier.is_a?(HeadMusic::Rudiment::Alteration)

    all.detect do |alteration|
      alteration.representions.include?(identifier)
    end
  end

  def self.by(key, value)
    all.detect do |alteration|
      alteration.send(key) == value if %i[cents semitones].include?(key.to_sym)
    end
  end

  def self.from_string(string)
    string = string.to_s.strip
    all.detect do |alteration|
      alteration.representions.include?(string)
    end
  end

  def self.get_by_name(name)
    all.detect { |alteration| alteration.name == name.to_s }
  end

  def self.from_pitched_item(input)
    nil
  end

  def name(locale_code: I18n.locale)
    super || identifier.to_s.tr("_", " ")
  end

  def representions
    [identifier, identifier.to_s, name, ascii, unicode, html_entity]
      .reject { |representation| representation.to_s.strip == "" }
  end

  def semitones
    cents / 100.0
  end

  ALTERATION_IDENTIFIERS.each do |key|
    define_method(:"#{key}?") { identifier == key }
  end

  def to_s
    unicode
  end

  def <=>(other)
    other = HeadMusic::Rudiment::Alteration.get(other)
    cents <=> other.cents
  end

  def musical_symbol
    musical_symbols.first
  end

  private

  def initialize(attributes)
    @identifier = attributes[:identifier]
    @cents = attributes[:cents]
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
      HeadMusic::Rudiment::MusicalSymbol.new(
        unicode: record[:unicode],
        ascii: record[:ascii],
        html_entity: record[:html_entity]
      )
    end
  end

  private_class_method :new
end
