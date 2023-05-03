# frozen_string_literal: true

# A reference pitch has a pitch and a frequency
# With no arguments, it assumes that A4 = 440.0 Hz
class HeadMusic::ReferencePitch
  include HeadMusic::Named

  DEFAULT_PITCH_NAME = "A4"
  DEFAULT_FREQUENCY = 440.0
  DEFAULT_REFERENCE_PITCH_NAME = "A440"

  NAMED_REFERENCE_PITCHES = [
    {
      frequency: 415.0,
      key: :baroque,
      alias_keys: %i[chamber_tone]
    },
    {
      frequency: 430.0,
      key: :classical,
      alias_keys: %i[haydn mozart]
    },
    {
      pitch: "C4",
      frequency: 256.0,
      key: :scientific,
      alias_keys: %i[philosophical sauveur]
    },
    {
      frequency: 432.0,
      tuning: "Pythagorean",
      key: :verdi
    },
    {
      frequency: 435.0,
      key: :french,
      alias_keys: %i[continental international]
    },
    {
      frequency: 439.0,
      key: :new_philharmonic,
      alias_keys: %i[low]
    },
    {
      frequency: 440.0,
      key: :a440,
      alias_keys: %i[concert stuttgart scheibler iso_16]
    },
    {
      frequency: 441.0,
      key: :sydney_symphony_orchestra
    },
    {
      frequency: 442.0,
      key: :new_york_philharmonic
    },
    {
      frequency: 443.0,
      key: :berlin_philharmonic
    },
    {
      frequency: 444.0,
      key: :boston_symphony_orchestra
    },
    {
      frequency: 452.4,
      key: :old_philharmonic,
      alias_keys: %i[high]
    },
    {
      frequency: 466.0,
      key: :chorton,
      alias_keys: %i[choir]
    }
  ].freeze

  attr_reader :pitch, :frequency

  def self.get(name)
    return name if name.is_a?(self)
    get_by_name(name)
  end

  def initialize(name = DEFAULT_REFERENCE_PITCH_NAME)
    record = named_reference_pitch_record_for_name(name)
    @pitch = HeadMusic::Pitch.get(record.fetch(:pitch, DEFAULT_PITCH_NAME))
    @frequency = record.fetch(:frequency, DEFAULT_FREQUENCY)
    initialize_keys_from_record(record)
  end

  def description
    [
      pitch.letter_name,
      format(
        "%<with_digits>g",
        with_digits: format("%.2<frequency>f", frequency: frequency)
      )
    ].join("=")
  end

  def to_s
    description
  end

  private

  def named_reference_pitch_record_for_name(name)
    key = HeadMusic::Utilities::HashKey.for(normalized_name_string(name))
    NAMED_REFERENCE_PITCHES.detect do |record|
      name_keys_from_record(record).include?(key)
    end || named_reference_pitch_record_for_name(DEFAULT_REFERENCE_PITCH_NAME)
  end

  def name_keys_from_record(record)
    names_from_record(record).map { |name| HeadMusic::Utilities::HashKey.for(name) }
  end

  def names_from_record(record)
    name_keys = ([record[:key]] + [record[:alias_keys]]).flatten.compact.uniq
    normalized_translations_for_keys(name_keys)
  end

  def normalized_name_string(name)
    name.gsub(" pitch", "").gsub(" tone", "").gsub(" tuning", "")
  end

  def initialize_keys_from_record(record)
    @key = record[:key]
    @alias_keys = [record[:alias_keys]].flatten.compact
  end

  def normalized_translations_for_keys(name_keys)
    name_and_alias_translations_for_keys(name_keys).map do |name|
      normalized_name_string(name)
    end
  end

  def name_and_alias_translations_for_keys(name_keys)
    name_keys.map do |name_key|
      I18n.config.available_locales.map do |locale_code|
        I18n.translate(name_key, scope: :reference_pitches, locale: locale_code)
      end.flatten.uniq.compact
    end.flatten.uniq.compact
  end
end
