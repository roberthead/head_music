# frozen_string_literal: true

# A reference pitch has a pitch and a frequency
# With no arguments, it assumes that A4 = 440.0 Hz
class HeadMusic::ReferencePitch
  include HeadMusic::Named

  DEFAULT_PITCH_NAME = 'A4'
  DEFAULT_FREQUENCY = 440.0

  NAMED_REFERENCE_PITCHES = [
    { name: 'Baroque', pitch: 'A4', frequency: 415.0 },
    { name: 'Classical', pitch: 'A4', frequency: 430.0 },
    { name: 'Scientific', pitch: 'C4', frequency: 256.0 },
    { name: 'Verdi', pitch: 'A4', frequency: 432.0 }, # Pythagorean tuning
    { name: 'French', pitch: 'A4', frequency: 435.0 },
    { name: 'New Philharmonic', pitch: 'A4', frequency: 439.0 },
    { name: 'A440', pitch: 'A4', frequency: 440.0 },
    { name: 'Sydney Symphony Orchestra', pitch: 'A4', frequency: 441.0 },
    { name: 'New York Philharmonic', pitch: 'A4', frequency: 442.0 },
    { name: 'Berlin Philharmonic', pitch: 'A4', frequency: 443.0 },
    { name: 'Boston Symphony Orchestra', pitch: 'A4', frequency: 444.0 },
    { name: 'Old Philharmonic', pitch: 'A4', frequency: 452.4 },
    { name: 'Chorton', pitch: 'A4', frequency: 466.0 },
  ].freeze

  ALIAS_DATA = [
    { key: :baroque, name: 'Kammerton' },
    { key: :classical, name: 'Haydn' },
    { key: :classical, name: 'Mozart' },
    { key: :scientific, name: 'philosophical' },
    { key: :scientific, name: 'Sauveur' },
    { key: :scientific, name: 'Schiller' },
    { key: :french, name: 'continental' },
    { key: :french, name: 'international' },
    { key: :new_philharmonic, name: 'low' },
    { key: :old_philharmonic, name: 'high' },
    { key: :a440, name: 'concert' },
    { key: :a440, name: 'Stuttgart' },
    { key: :a440, name: 'Scheibler' },
    { key: :a440, name: 'ISO 16' },
    { key: :chorton, name: 'choir' },
  ].freeze

  attr_reader :pitch, :frequency

  def self.aliases
    @aliases ||= ALIAS_DATA.map { |attributes| HeadMusic::Named::Alias.new(attributes) }
  end

  def self.get(name)
    return name if name.is_a?(self)
    get_by_name(name)
  end

  def initialize(name = 'A440')
    @name = name.to_s
    reference_pitch_data = NAMED_REFERENCE_PITCHES.detect do |candidate|
      candidate_name_key = HeadMusic::Utilities::HashKey.for(candidate[:name])
      [candidate_name_key, candidate_name_key.to_s.delete('_').to_sym].include?(normalized_key)
    end || {}
    @pitch = HeadMusic::Pitch.get(reference_pitch_data.fetch(:pitch, DEFAULT_PITCH_NAME))
    @frequency = reference_pitch_data.fetch(:frequency, DEFAULT_FREQUENCY)
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

  def normalized_key
    @normalized_key ||= begin
      key = HeadMusic::Utilities::HashKey.for(name.to_s.gsub(/\W?(pitch|tuning|tone)/, ''))
      HeadMusic::ReferencePitch.aliases.detect do |alias_data|
        HeadMusic::Utilities::HashKey.for(alias_data.name) == key
      end&.key || key
    end
  end
end
