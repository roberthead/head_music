class HeadMusic::KeySignature
  attr_reader :tonic_spelling
  attr_reader :scale_type

  SHARPS = %w{F# C# G# D# A# E# B#}
  FLATS = %w{Bb Eb Ab Db Gb Cb Fb}

  delegate :pitch_class, to: :tonic_spelling, prefix: :tonic

  def initialize(tonic_spelling, scale_type = :major)
    @tonic_spelling = tonic_spelling
    @scale_type = scale_type
  end

  def sharps
    SHARPS.first(num_sharps)
  end

  def flats
    FLATS.first(num_flats)
  end

  def num_sharps
    (HeadMusic::Circle.of_fifths.pitch_classes.index(tonic_pitch_class) - scale_type_adjustment) % 12
  end

  def num_flats
    (HeadMusic::Circle.of_fourths.pitch_classes.index(tonic_pitch_class) + scale_type_adjustment) % 12
  end

  private

  def scale_type_adjustment
    scale_type == :minor ? 3 : 0
  end
end
