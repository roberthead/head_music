class HeadMusic::Pitch
  include Comparable

  attr_reader :spelling
  attr_reader :octave

  delegate :letter_name, :letter_name_cycle, to: :spelling
  delegate :accidental, :sharp?, :flat?, to: :spelling
  delegate :pitch_class, to: :spelling
  delegate :semitones, to: :accidental, prefix: true, allow_nil: true

  delegate :smallest_interval_to, to: :pitch_class

  def self.get(value)
    from_name(value) || from_number(value)
  end
  singleton_class.send(:alias_method, :[], :get)

  def self.from_name(name)
    return nil unless name == name.to_s
    fetch_or_create(HeadMusic::Spelling.get(name), HeadMusic::Octave.get(name).to_i)
  end

  def self.from_number(number)
    return nil unless number == number.to_i
    spelling = HeadMusic::Spelling.from_number(number)
    octave = (number.to_i / 12) - 1
    fetch_or_create(spelling, octave)
  end

  def self.from_number_and_letter(number, letter_name)
    letter_name = HeadMusic::LetterName.get(letter_name)
    natural_letter_pitch = get(HeadMusic::LetterName.get(letter_name).pitch_class)
    natural_letter_pitch += 12 while (number - natural_letter_pitch.to_i).to_i >= 11
    natural_letter_pitch = get(natural_letter_pitch)
    accidental_interval = natural_letter_pitch.smallest_interval_to(HeadMusic::PitchClass.get(number))
    accidental = HeadMusic::Accidental.for_interval(accidental_interval)
    spelling = HeadMusic::Spelling.fetch_or_create(letter_name, accidental)
    fetch_or_create(spelling, natural_letter_pitch.octave)
  end

  def self.fetch_or_create(spelling, octave)
    @pitches ||= {}
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
    (octave + 1) * 12 + letter_name.pitch_class.to_i + accidental_semitones.to_i
  end

  alias_method :midi, :midi_note_number
  alias_method :number, :midi_note_number

  def to_s
    name
  end

  def to_i
    midi_note_number
  end

  def natural
    HeadMusic::Pitch.get(self.to_s.gsub(/[#b]/, ''))
  end

  def enharmonic?(other)
    self.midi_note_number == other.midi_note_number
  end

  def +(value)
    Pitch.get(self.to_i + value.to_i)
  end

  def -(value)
    if value.is_a?(HeadMusic::Pitch)
      # return an interval
      HeadMusic::Interval.get(self.to_i - value.to_i)
    else
      # assume value represents an interval in semitones and return another pitch
      HeadMusic::Pitch.get(self.to_i - value.to_i)
    end
  end

  def ==(value)
    to_s == value.to_s
  end

  def <=>(other)
    self.midi_note_number <=> other.midi_note_number
  end

  def scale(scale_type_name = nil)
    HeadMusic::Scale.get(self, scale_type_name)
  end

  def natural_steps(num_steps)
    target_letter_name = self.letter_name.steps(num_steps)
    direction = num_steps >= 0 ? 1 : -1
    octaves_delta = (num_steps.abs / 7) * direction
    if num_steps < 0 && target_letter_name.position > letter_name.position
      octaves_delta -= 1
    elsif num_steps > 0 && target_letter_name.position < letter_name.position
      octaves_delta += 1
    end
    HeadMusic::Pitch.get([target_letter_name, octave + octaves_delta].join)
  end

  private_class_method :new
end
