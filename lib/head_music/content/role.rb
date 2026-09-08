# A module for musical content
module HeadMusic::Content; end

# The part a person played. Roles are grouped by the level they attach to, so
# the model cannot record a publisher as having composed the music.
class HeadMusic::Content::Role
  include HeadMusic::Named

  KEYS_BY_LEVEL = {
    work: %i[composer songwriter lyricist librettist],
    project: %i[arranger transcriber orchestrator reconstructor],
    publication: %i[author editor engraver publisher]
  }.freeze

  KEYS = KEYS_BY_LEVEL.values.flatten.freeze
  LEVELS = KEYS_BY_LEVEL.keys.freeze

  # Unlike Named's .get_by_name, an unrecognized identifier raises rather than
  # minting a role: the twelve roles are the whole vocabulary.
  def self.get(identifier)
    return identifier if identifier.is_a?(self)

    key = key_for(identifier)
    raise ArgumentError, "unknown credit role: #{identifier.inspect}" if key.nil?

    @instances ||= {}
    @instances[key] ||= new(key)
  end

  def self.for_level(level)
    keys = KEYS_BY_LEVEL[level&.to_sym]
    raise ArgumentError, "unknown credit level: #{level.inspect}" if keys.nil?

    keys.map { |key| get(key) }
  end

  def self.all
    KEYS.map { |key| get(key) }
  end

  def self.key_for(identifier)
    return nil if identifier.nil?

    key = HeadMusic::Utilities::HashKey.for(identifier)
    return key if KEYS.include?(key)

    key_for_translated_name(identifier.to_s.strip)
  end

  def self.key_for_translated_name(name)
    return nil if name.empty?

    KEYS.detect do |key|
      I18n.config.available_locales.any? do |locale_code|
        I18n.translate(key, scope: "head_music.credit_roles", locale: locale_code).casecmp?(name)
      end
    end
  end
  private_class_method :key_for_translated_name

  attr_reader :key

  def level
    @level ||= KEYS_BY_LEVEL.detect { |_level, keys| keys.include?(key) }.first
  end

  def name(locale_code: Locale::DEFAULT_CODE)
    I18n.translate(name_key, scope: "head_music.credit_roles", locale: locale_code)
  end

  def ==(other)
    return eql?(other) if other.is_a?(self.class)
    return false unless other.is_a?(Symbol) || other.is_a?(String)

    key == self.class.key_for(other)
  end

  def eql?(other)
    other.is_a?(self.class) && key == other.key
  end

  def hash
    [self.class, key].hash
  end

  private_class_method :new

  private

  def initialize(key)
    @key = key
    @name_key = key
  end
end
