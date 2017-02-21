class HeadMusic::FunctionalInterval
  NUMBER_NAMES = %w[unison second third fourth fifth sixth seventh octave ninth tenth eleventh twelfth thirteenth fourteenth fifteenth sixteenth seventeenth]
  NAME_SUFFIXES = Hash.new('th').merge({ 1 => 'st', 2 => 'nd', 3 => 'rd' })

  QUALITY_SEMITONES = {
    unison: { perfect: 0 },
    second: { major: 2 },
    third: { major: 4 },
    fourth: { perfect: 5 },
    fifth: { perfect: 7 },
    sixth: { major: 9 },
    seventh: { major: 11 },
    octave: { perfect: 12 },
    ninth: { major: 14 },
    tenth: { major: 16 },
    eleventh: { perfect: 17 },
    twelfth: { perfect: 19 },
    thirteenth: { major: 21 },
    fourteenth: { major: 23 },
    fifteenth: { perfect: 24 },
    sixteenth: { major: 26 },
    seventeenth: { major: 28 }
  }

  attr_reader :lower_pitch, :higher_pitch

  delegate :to_s, to: :name
  delegate :==, to: :to_s

  def self.get(name)
    words = name.to_s.split(/[_ ]+/)
    quality_name, degree_name = words[0..-2].join(' '), words.last
    lower_pitch = HeadMusic::Pitch.get('C4')
    steps = NUMBER_NAMES.index(degree_name)
    higher_letter = lower_pitch.letter.steps(steps)
    semitones = degree_quality_semitones.dig(degree_name.to_sym, quality_name.to_sym)
    higher_pitch = HeadMusic::Pitch.from_number_and_letter(lower_pitch + semitones, higher_letter)
    new(lower_pitch, higher_pitch)
  end

  def self.degree_quality_semitones
    @degree_quality_semitones ||= begin
      degree_quality_semitones = QUALITY_SEMITONES
      QUALITY_SEMITONES.each do |degree_name, qualities|
        default_quality = qualities.keys.first
        if default_quality == :perfect
          modification_hash = HeadMusic::Quality::PERFECT_INTERVAL_MODIFICATION.invert
        else
          modification_hash = HeadMusic::Quality::MAJOR_INTERVAL_MODIFICATION.invert
        end
        default_semitones = qualities[default_quality]
        modification_hash.each do |quality_name, delta|
          if quality_name != default_quality
            degree_quality_semitones[degree_name][quality_name] = default_semitones + delta
          end
        end
      end
      degree_quality_semitones
    end
  end

  def initialize(pitch1, pitch2)
    @lower_pitch, @higher_pitch = [HeadMusic::Pitch.get(pitch1), HeadMusic::Pitch.get(pitch2)].sort
  end

  def number
    simple_number + octaves * 7
  end

  def simple_number
    @simple_number ||= @lower_pitch.letter.steps_to(@higher_pitch.letter) + 1
  end

  def simple_semitones
    semitones % 12
  end

  def semitones
    (@higher_pitch - @lower_pitch).to_i
  end

  def octaves
    (higher_pitch.number - lower_pitch.number) / 12
  end

  def compound?
    !simple?
  end

  def simple?
    octaves == 0
  end

  def simple_name
    [quality_name, simple_number_name].join(' ')
  end

  def name
    if number < NUMBER_NAMES.length
      [quality_name, number_name].join(' ')
    elsif simple_name == 'perfect unison'
      string = "#{octaves.humanize} octaves"
    else
      "#{octaves.humanize} octaves and #{quality.article} #{simple_name}"
    end
  end

  def shorthand
    [quality.shorthand, number].join
  end

  def quality
    HeadMusic::Quality.get(quality_name)
  end

  def quality_name
    starting_quality = QUALITY_SEMITONES[simple_number_name.to_sym].keys.first
    delta = simple_semitones - QUALITY_SEMITONES[simple_number_name.to_sym][starting_quality]
    HeadMusic::Quality::from(starting_quality, delta)
  end

  def simple_number_name
    NUMBER_NAMES[simple_number - 1]
  end

  def number_name
    NUMBER_NAMES[number - 1] || begin
      number.to_s + NAME_SUFFIXES[number % 10]
    end
  end

  def inversion
    inverted_low_pitch = lower_pitch
    while inverted_low_pitch < higher_pitch
      inverted_low_pitch += 12
    end
    HeadMusic::FunctionalInterval.new(higher_pitch, inverted_low_pitch)
  end
end
