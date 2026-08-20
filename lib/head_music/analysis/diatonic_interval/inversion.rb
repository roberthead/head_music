class HeadMusic::Analysis::DiatonicInterval
  # Inverting an interval puts its lower pitch on top. The lower pitch keeps its
  # spelling and climbs by whole octaves until it is no longer below the pitch
  # it is being inverted over, and the interval is read from there. Climbing by
  # octaves rather than computing the register outright is what keeps the
  # spelling honest at the edges, where C♭5 sits below B♯4.
  class Inversion
    attr_reader :lower_pitch, :higher_pitch

    def initialize(lower_pitch, higher_pitch)
      @lower_pitch = lower_pitch
      @higher_pitch = higher_pitch
    end

    def interval
      HeadMusic::Analysis::DiatonicInterval.new(higher_pitch, raised_lower_pitch)
    end

    private

    def raised_lower_pitch
      pitch = lower_pitch
      pitch = octave_above(pitch) while pitch < higher_pitch
      pitch
    end

    def octave_above(pitch)
      HeadMusic::Rudiment::Pitch.fetch_or_create(lower_pitch.spelling, pitch.register + 1)
    end
  end
end
