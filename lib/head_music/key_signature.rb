class HeadMusic::KeySignature
  attr_reader :tonic_spelling
  attr_reader :quality_name

  SHARPS = %w{F# C# G# D# A# E# B#}
  FLATS = %w{Bb Eb Ab Db Gb Cb Fb}

  def self.default
    @default ||= new('C', :major)
  end

  def self.get(identifier)
    return identifier if identifier.is_a?(HeadMusic::KeySignature)
    @key_signatures ||= {}
    tonic_spelling, quality_name = identifier.split(/\s/)
    hash_key = HeadMusic::Utilities::HashKey.for(identifier)
    @key_signatures[hash_key] ||= new(tonic_spelling, quality_name)
  end

  delegate :pitch_class, to: :tonic_spelling, prefix: :tonic
  delegate :to_s, to: :name

  def initialize(tonic_spelling, quality_name = nil)
    @tonic_spelling = tonic_spelling
    @quality_name = quality_name || :major
  end

  def sharps
    SHARPS.first(num_sharps)
  end

  def flats
    FLATS.first(num_flats)
  end

  def num_sharps
    (HeadMusic::Circle.of_fifths.index(tonic_pitch_class) - quality_name_adjustment) % 12
  end

  def num_flats
    (HeadMusic::Circle.of_fourths.index(tonic_pitch_class) + quality_name_adjustment) % 12
  end

  def sharps_or_flats
    return sharps if @tonic_spelling.to_s =~ /#/
    return flats if @tonic_spelling.to_s =~ /b/
    num_sharps <= num_flats ? sharps : flats
  end

  def name
    [tonic_spelling.to_s, quality_name.to_s].join(' ')
  end

  def ==(other)
    self.to_s == other.to_s
  end

  private

  def quality_name_adjustment
    quality_name == :minor ? 3 : 0
  end

  def major?
    @quality_name.to_sym == :major
  end

  def minor?
    @quality_name.to_sym == :minor
  end

  def relative_major_pitch_class
    return tonic_pitch_class if major?
    return (tonic_pitch_class.to_i + 3) % 12 if minor?
  end
end
