class HeadMusic::Pitch
  include Comparable

  DEFAULT_OCTAVE = 4

  attr_reader :spelling
  attr_reader :octave

  delegate :letter, :accidental, :pitch_class, to: :spelling

  def self.get(value)
    @pitches ||= {}
    @pitches[value] ||= from_name(value) || from_number(value)
  end

  def self.from_name(name)
    return nil unless name == name.to_s
    fetch_or_create(HeadMusic::Spelling.get(name), octave_from_name(name))
  end

  def self.octave_from_name(name)
    (name.to_s.scan(/-?\d+$/).first || DEFAULT_OCTAVE).to_i
  end

  def self.from_number(number)
    return nil unless number == number.to_i
    spelling = HeadMusic::Spelling.from_number(number)
    octave = (number.to_i / 12) - 1
    fetch_or_create(spelling, octave)
  end

  def self.fetch_or_create(spelling, octave)
    if spelling && (-1..9).include?(octave)
      key = [spelling, octave].join
      @pitches[key] ||= new(spelling, octave)
    end
  end

  def initialize(spelling, octave)
    @spelling = HeadMusic::Spelling.get(spelling.to_s)
    @octave = octave.to_i
  end

  def name
    [spelling, octave].join
  end

  def midi_note_number
    (octave + 1) * 12 + pitch_class.to_i
  end

  alias_method :midi, :midi_note_number

  def to_s
    name
  end

  def to_i
    midi_note_number
  end

  def enharmonic?(other)
    self.midi_note_number == other.midi_note_number
  end

  def ==(value)
    to_s == value.to_s
  end

  def <=>(other)
    self.midi_note_number <=> other.midi_note_number
  end

  private_class_method :new
end
