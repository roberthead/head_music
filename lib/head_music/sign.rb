# frozen_string_literal: true

require 'head_music/musical_symbol'

# A Sign is a symbol that modifies pitch, such as a sharp, flat, or natural.
class HeadMusic::Sign
  include Comparable

  attr_reader :identifier, :cents, :musical_symbol

  delegate :ascii, :unicode, :html_entity, to: :musical_symbol

  SIGN_DATA = [
    { identifier: :sharp, ascii: '#', unicode: '♯', html_entity: '&#9839;', cents: 100 },
    { identifier: :flat, ascii: 'b', unicode: '♭', html_entity: '&#9837;', cents: -100 },
    { identifier: :natural, ascii: '', unicode: '♮', html_entity: '&#9838;', cents: 0 },
    { identifier: :double_sharp, ascii: 'x', unicode: '𝄪', html_entity: '&#119082;', cents: 200 },
    { identifier: :double_flat, ascii: 'bb', unicode: '𝄫', html_entity: '&#119083;', cents: -200 },
  ].freeze

  SIGN_IDENTIFIERS = SIGN_DATA.map { |attributes| attributes[:identifier] }.freeze

  def self.all
    SIGN_DATA.map { |attributes| new(attributes) }
  end

  def self.symbols
    @symbols ||= all.map { |sign| [sign.ascii, sign.unicode] }.flatten.reject { |s| s.nil? || s.empty? }
  end

  def self.matcher
    @matcher ||= Regexp.new symbols.join('|')
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
    identifier.to_s.tr('_', ' ')
  end

  def representions
    [identifier, identifier.to_s, name, ascii, unicode, html_entity].
      reject { |representation| representation.to_s.strip == '' }
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

  private

  def initialize(attributes)
    @identifier = attributes[:identifier]
    @cents = attributes[:cents]
    @musical_symbol = HeadMusic::MusicalSymbol.new(
      unicode: attributes[:unicode],
      ascii: attributes[:ascii],
      html_entity: attributes[:html_entity]
    )
  end

  private_class_method :new
end
