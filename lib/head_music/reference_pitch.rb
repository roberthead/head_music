# frozen_string_literal: true

# A reference pitch has a pitch and a frequency
# With no arguments, it assumes that A4 = 440.0 Hz
class HeadMusic::ReferencePitch
  include HeadMusic::NamedRudiment

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

  ALIASES = {
    kammerton: :baroque,
    chamber: :baroque,
    haydn: :classical,
    mozart: :classical,
    philosophic: :scientific,
    sauveur: :scientific,
    schiller: :scientific,
    continental: :french,
    international: :french,
    low: :new_philharmonic,
    concert: :a440,
    stuttgart: :a440,
    scheibler: :a440,
    iso_16: :a440,
    high: :old_philharmonic,
    choir: :chorton,
  }.freeze

  NAMED_REFERENCE_PITCH_NAMES = NAMED_REFERENCE_PITCHES.map { |pitch_data| pitch_data[:name] }

  attr_reader :pitch, :frequency

  def self.get(name)
    return name if name.is_a?(self)
    get_by_name(name)
  end

  def initialize(name = 'A440')
    @name = name.to_s
    reference_pitch_data = NAMED_REFERENCE_PITCHES.detect do |candidate|
      candidate_name_key = HeadMusic::Utilities::HashKey.for(candidate[:name])
      [candidate_name_key, candidate_name_key.to_s.delete('_').to_sym].include?(normalized_name)
    end || {}
    @pitch = HeadMusic::Pitch.get(reference_pitch_data.fetch(:pitch, DEFAULT_PITCH_NAME))
    @frequency = reference_pitch_data.fetch(:frequency, DEFAULT_FREQUENCY)
  end

  def description
    [
      pitch.letter_name,
      format(
        '%<with_digits>g',
        with_digits: format('%.2f', frequency)
      ),
    ].join('=')
  end

  def to_s
    description
  end

  private

  def normalized_name
    @normalized_name ||= begin
      key = HeadMusic::Utilities::HashKey.for(name.to_s.gsub(/\W?(pitch|tuning|tone)/, ''))
      ALIASES[key] || key
    end
  end
end
