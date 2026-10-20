class HeadMusic::Style::Guidelines::Contoured
  # Reads a melody's legs against a wave, which turns more than once.
  class WaveReading
    WAVE_LEGS = 3

    # Running state for the zigzag walk in #legs.
    TrendWalk = Struct.new(:legs, :leg, :high, :low, :extreme)

    attr_reader :contour, :pitch_numbers

    def initialize(contour, pitch_numbers)
      @contour = contour
      @pitch_numbers = pitch_numbers
    end

    def degree
      return missing_legs if missing_legs.positive?

      single_turn? ? 1 : 0
    end

    def miss
      missing_legs.positive? ? "too_few_legs" : "single_turn"
    end

    private

    def missing_legs
      [WAVE_LEGS - legs.length, 0].max
    end

    # Legs enough for a wave may still be ornaments on one arch or valley.
    def single_turn?
      TurnReading::MIRRORS.each_key.any? { |shape| TurnReading.new(shape, pitch_numbers).degree.zero? }
    end

    # A reversal counts only once the melody retraces TREND_REVERSAL_SEMITONES
    # from the running extreme, so neighbor-note undulation is not a new leg.
    def legs
      @legs ||= begin
        first = pitch_numbers.first
        walk = TrendWalk.new([], nil, first, first, nil)
        pitch_numbers.drop(1).each { |number| advance_leg(walk, number) }
        walk.legs
      end
    end

    def advance_leg(walk, number)
      if walk.leg.nil?
        seek_leg(walk, number)
      else
        continue_leg(walk, number)
      end
    end

    def seek_leg(walk, number)
      if number - walk.low >= TREND_REVERSAL_SEMITONES
        start_leg(walk, :rise, number)
      elsif walk.high - number >= TREND_REVERSAL_SEMITONES
        start_leg(walk, :fall, number)
      else
        walk.high = [walk.high, number].max
        walk.low = [walk.low, number].min
      end
    end

    def continue_leg(walk, number)
      sign = (walk.leg == :rise) ? 1 : -1
      delta = number - walk.extreme
      if sign * delta > 0
        walk.extreme = number
      elsif -sign * delta >= TREND_REVERSAL_SEMITONES
        start_leg(walk, opposite_leg(walk.leg), number)
      end
    end

    def start_leg(walk, leg, number)
      walk.leg = leg
      walk.extreme = number
      walk.legs << leg
    end

    def opposite_leg(leg)
      (leg == :rise) ? :fall : :rise
    end
  end
end
