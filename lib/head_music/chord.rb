class HeadMusic::Chord
  attr_reader :pitches

  def initialize(pitches)
    raise ArgumentError if pitches.length < 3
    @pitches = pitches.map { |pitch| Pitch.get(pitch) }.sort
  end

  def consonant_triad?
    pitches.length == 3 &&
    (
      intervals.map(&:shorthand).sort == %w[M3 m3] ||
      invert.intervals.map(&:shorthand).sort == %w[M3 m3] ||
      invert.invert.intervals.map(&:shorthand).sort == %w[M3 m3]
    )
  end

  def intervals
    pitches[1..-1].map.with_index do |pitch, i|
      FunctionalInterval.new(pitches[i], pitch)
    end
  end

  def invert
    inverted_pitch = pitches[0] + HeadMusic::Interval.get(12)
    new_pitches = pitches[1..-1] + [inverted_pitch]
    HeadMusic::Chord.new(new_pitches)
  end
end
