class HeadMusic::Style::Guidelines::Contoured
  # Reads a melody's legs against an arch, valley, or wave.
  class ShapeReading
    REQUIRED_LEGS = {arch: %i[rise fall], valley: %i[fall rise]}.freeze
    WAVE_LEGS = 3

    LegMiss = Data.define(:extra, :missing)

    # Running state for the zigzag walk in #legs.
    TrendWalk = Struct.new(:legs, :leg, :high, :low, :extreme)

    attr_reader :contour, :pitch_numbers

    def initialize(contour, pitch_numbers)
      @contour = contour
      @pitch_numbers = pitch_numbers
    end

    def degree
      leg_miss.extra + leg_miss.missing
    end

    # Extra and missing legs together happen only for the mirror shape.
    def miss
      return "too_few_legs" if contour == :wave

      if leg_miss.extra.positive?
        leg_miss.missing.positive? ? "reversed_legs" : "extra_legs"
      elsif leg_miss.missing == 1
        "missing_#{(REQUIRED_LEGS.fetch(contour) - legs).first}"
      else
        "missing_legs"
      end
    end

    private

    # Legs alternate, so a lone leg always matches one end of a required pair,
    # and three or more always contain the pair.
    def leg_miss
      @leg_miss ||=
        if contour == :wave
          LegMiss.new(extra: 0, missing: [WAVE_LEGS - legs.length, 0].max)
        else
          required = REQUIRED_LEGS.fetch(contour)
          matched = legs.each_cons(required.length).include?(required) ? required.length : [legs.length, 1].min
          LegMiss.new(extra: legs.length - matched, missing: required.length - matched)
        end
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
