# frozen_string_literal: true

# A reference pitch has a pitch and a frequency
# With no arguments, it assumes that A4 = 440.0 Hz
class HeadMusic::ReferencePitch
  include HeadMusic::Named

  DEFAULT_PITCH_NAME = 'A4'
  DEFAULT_FREQUENCY = 440.0
  DEFAULT_REFERENCE_PITCH_NAME = 'A440'

  NAMED_REFERENCE_PITCHES = [
    { name: 'Baroque', frequency: 415.0, aliases: %w[Kammerton] },
    { name: 'Classical', frequency: 430.0, aliases: %w[Haydn Mozart] },
    { name: 'Scientific', pitch: 'C4', frequency: 256.0, aliases: %w[philosophical Sauveur Schiller] },
    { name: 'Verdi', frequency: 432.0 }, # Pythagorean tuning
    { name: 'French', frequency: 435.0, aliases: %w[continental international] },
    { name: 'New Philharmonic', frequency: 439.0, aliases: %w[low] },
    { name: 'A440', frequency: 440.0, aliases: ['concert', 'Stuttgart', 'Scheibler', 'ISO 16'] },
    { name: 'Sydney Symphony Orchestra', frequency: 441.0 },
    { name: 'New York Philharmonic', frequency: 442.0 },
    { name: 'Berlin Philharmonic', frequency: 443.0 },
    { name: 'Boston Symphony Orchestra', frequency: 444.0 },
    { name: 'Old Philharmonic', frequency: 452.4, aliases: %w[high] },
    { name: 'Chorton', frequency: 466.0, aliases: ['choir'] },
  ].freeze

  attr_reader :pitch, :frequency, :aliases

  def self.get(name)
    return name if name.is_a?(self)
    get_by_name(name)
  end

  def initialize(name = DEFAULT_REFERENCE_PITCH_NAME)
    @name = name.to_s
    record = named_reference_pitch_record_for_name(name)
    @pitch = HeadMusic::Pitch.get(record.fetch(:pitch, DEFAULT_PITCH_NAME))
    @frequency = record.fetch(:frequency, DEFAULT_FREQUENCY)
    @aliases = record.fetch(:aliases, [])
  end

  def description
    [
      pitch.letter_name,
      format(
        '%<with_digits>g',
        with_digits: format('%.2<frequency>f', frequency: frequency)
      ),
    ].join('=')
  end

  def to_s
    description
  end

  private

  def named_reference_pitch_record_for_name(name)
    key = HeadMusic::Utilities::HashKey.for(name)
    NAMED_REFERENCE_PITCHES.detect do |record|
      name_keys_from_record(record).include?(key)
    end || named_reference_pitch_record_for_name(DEFAULT_REFERENCE_PITCH_NAME)
  end

  def name_keys_from_record(record)
    names_from_record(record).map { |name| HeadMusic::Utilities::HashKey.for(name) }
  end

  def names_from_record(record)
    [record[:name]] + record.fetch(:aliases, [])
  end
end
