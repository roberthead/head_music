class HeadMusic::KeySignature
  attr_reader :tonic_spelling
  attr_reader :scale_type

  SHARPS = %w{F# C# G# D# A# E# B#}
  FLATS = %w{Bb Eb Ab Db Gb Cb Fb}

  delegate :pitch_class, to: :tonic_spelling, prefix: :tonic

  def initialize(tonic_spelling, scale_type = nil)
    @tonic_spelling = tonic_spelling
    @scale_type = scale_type || scale_type
  end

  def sharps
    SHARPS.first(num_sharps)
  end

  def flats
    FLATS.first(num_flats)
  end

  def num_sharps
    (HeadMusic::Circle.of_fifths.index(tonic_pitch_class) - scale_type_adjustment) % 12
  end

  def num_flats
    (HeadMusic::Circle.of_fourths.index(tonic_pitch_class) + scale_type_adjustment) % 12
  end

  def sharps_or_flats
    return sharps if @tonic_spelling.to_s =~ /#/
    return flats if @tonic_spelling.to_s =~ /b/
    num_sharps <= num_flats ? sharps : flats
  end

  private

  def scale_type_adjustment
    scale_type == :minor ? 3 : 0
  end

  def major?
    @scale_type.to_sym == :major
  end

  def minor?
    @scale_type.to_sym == :minor
  end

  def relative_major_pitch_class
    return tonic_pitch_class if major?
    return (tonic_pitch_class.to_i + 3) % 12 if minor?
  end
end
