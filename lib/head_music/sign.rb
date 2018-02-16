class HeadMusic::Sign
  include Comparable

  attr_reader :identifier, :name, :ascii, :unicode, :html_entity, :cents

  def self.all
    @all ||= [
      new(identifier: :sharp, name: 'sharp', ascii: '#', unicode: "\u266F", html_entity: '&#9839;', cents: 100),
      new(identifier: :flat, name: 'flat', ascii: 'b', unicode: "\u266D", html_entity: '&#9837;', cents: -100),
      new(identifier: :natural, name: 'natural', ascii: '', unicode: "\u266E", html_entity: '&#9838;', cents: 0),
      new(identifier: :double_sharp, name: 'double sharp', ascii: '##', unicode: "\u{1D12A}", html_entity: '&#119082;', cents: 200),
      new(identifier: :double_flat, name: 'double flat', ascii: 'bb', unicode: "\u{1D12B}", html_entity: '&#119083;', cents: -200),
    ]
  end

  def self.get(identifier)
    return identifier if identifier.is_a?(HeadMusic::Sign)
    all.detect do |sign|
      sign.representions.include?(identifier)
    end
  end

  def self.by(key, value)
    all.detect do |sign|
      if %i[cents semitones].include?(key.to_sym)
        sign.send(key) == value
      end
    end
  end

  def representions
    [identifier, identifier.to_s, name, ascii, unicode, html_entity].reject { |representation| representation.to_s.strip == '' }
  end

  def semitones
    cents / 100.0
  end

  def to_s
    unicode
  end

  def <=>(other)
    other = HeadMusic::Sign.get(other)
    self.cents <=> other.cents
  end

  private

  def initialize(attributes)
    @identifier = attributes[:identifier]
    @name = attributes[:name]
    @ascii = attributes[:ascii]
    @unicode = attributes[:unicode]
    @html_entity = attributes[:html_entity]
    @cents = attributes[:cents]
  end

  private_class_method :new
end
