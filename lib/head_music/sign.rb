require "head_music/musical_symbol"

# A Sign is a symbol that modifies pitch, such as a sharp, flat, or natural.
# In French, sharps and flats in the key signature are called "altérations".
class HeadMusic::Sign
  include Comparable

  attr_reader :identifier, :cents, :musical_symbols

  delegate :ascii, :unicode, :html_entity, to: :musical_symbol

  SIGN_RECORDS = [
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

  SIGN_IDENTIFIERS = SIGN_RECORDS.map { |attributes| attributes[:identifier] }.freeze

  def self.all
    SIGN_RECORDS.map { |attributes| new(attributes) }
  end

  def self.symbols
    @symbols ||= all.map { |sign| [sign.ascii, sign.unicode] }.flatten.reject { |s| s.nil? || s.empty? }
  end

  def self.matcher
    @matcher ||= Regexp.new symbols.join("|")
  end

  def self.symbol?(candidate)
    candidate =~ /^(#{matcher})$/
  end

  def self.get(identifier)
    return identifier if identifier.is_a?(HeadMusic::Sign)

    all.detect do |sign|
      sign.representions.include?(identifier)
    end
  end

  def self.by(key, value)
    all.detect do |sign|
      sign.send(key) == value if %i[cents semitones].include?(key.to_sym)
    end
  end

  def name
    identifier.to_s.tr("_", " ")
  end

  def representions
    [identifier, identifier.to_s, name, ascii, unicode, html_entity]
      .reject { |representation| representation.to_s.strip == "" }
  end

  def semitones
    cents / 100.0
  end

  SIGN_IDENTIFIERS.each do |key|
    define_method(:"#{key}?") { identifier == key }
  end

  def to_s
    unicode
  end

  def <=>(other)
    other = HeadMusic::Sign.get(other)
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
  end

  def initialize_musical_symbols(list)
    @musical_symbols = (list || []).map do |record|
      HeadMusic::MusicalSymbol.new(
        unicode: record[:unicode],
        ascii: record[:ascii],
        html_entity: record[:html_entity]
      )
    end
  end

  private_class_method :new
end
