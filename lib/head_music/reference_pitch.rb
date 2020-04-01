# frozen_string_literal: true

# A reference pitch has a pitch and a frequency
# With no arguments, it assumes that A4 = 440.0 Hz
class HeadMusic::ReferencePitch
  include HeadMusic::Named

  DEFAULT_PITCH_NAME = 'A4'
  DEFAULT_FREQUENCY = 440.0
  DEFAULT_REFERENCE_PITCH_NAME = 'A440'

  NAMED_REFERENCE_PITCHES = [
    {
      frequency: 415.0,
      localized_names: [
        { name: 'Baroque' },
        { name: 'chamber tone' },
        { name: 'Kammerton', locale_code: 'de' },
      ],
    },
    {
      frequency: 430.0,
      localized_names: [
        { name: 'Classical' },
        { name: 'Haydn' },
        { name: 'Mozart' },
      ],
    },
    {
      pitch: 'C4',
      frequency: 256.0,
      localized_names: [
        { name: 'Scientific' },
        { name: 'philosophical' },
        { name: 'Sauveur' },
        { name: 'Schiller' },
      ],
    },
    {
      frequency: 432.0,
      tuning: 'Pythagorean',
      localized_names: [
        { name: 'Verdi' },
      ],
    },
    {
      frequency: 435.0,
      localized_names: [
        { name: 'French' },
        { name: 'continental' },
        { name: 'international' },
      ],
    },
    {
      frequency: 439.0,
      localized_names: [
        { name: 'New Philharmonic' },
        { name: 'low' },
      ],
    },
    {
      frequency: 440.0,
      localized_names: [
        { name: 'A440' },
        { name: 'concert' },
        { name: 'Stuttgart' },
        { name: 'Scheibler' },
        { name: 'ISO 16' },
      ],
    },
    {
      frequency: 441.0,
      localized_names: [{ name: 'Sydney Symphony Orchestra' }],
    },
    {
      frequency: 442.0,
      localized_names: [{ name: 'New York Philharmonic' }],
    },
    {
      frequency: 443.0,
      localized_names: [{ name: 'Berlin Philharmonic' }],
    },
    {
      frequency: 444.0,
      localized_names: [{ name: 'Boston Symphony Orchestra' }],
    },
    {
      frequency: 452.4,
      localized_names: [{ name: 'Old Philharmonic' }, { name: 'high' }],
    },
    {
      frequency: 466.0,
      localized_names: [
        { name: 'Chorton', locale_code: 'de' },
        { name: 'choir' },
      ],
    },
  ].freeze

  attr_reader :pitch, :frequency, :aliases

  def self.get(name)
    return name if name.is_a?(self)
    get_by_name(name)
  end

  def initialize(name = DEFAULT_REFERENCE_PITCH_NAME)
    record = named_reference_pitch_record_for_name(name)
    @pitch = HeadMusic::Pitch.get(record.fetch(:pitch, DEFAULT_PITCH_NAME))
    @frequency = record.fetch(:frequency, DEFAULT_FREQUENCY)
    @aliases = record.fetch(:aliases, [])
    @localized_names = record[:localized_names].map do |localized_name_data|
      HeadMusic::Named::LocalizedName.new(localized_name_data)
    end
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
    record[:localized_names].map { |data| data[:name] }
  end
end
