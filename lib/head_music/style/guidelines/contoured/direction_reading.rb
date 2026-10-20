class HeadMusic::Style::Guidelines::Contoured
  # Reads a melody's endpoints and headway against ascending or descending.
  class DirectionReading
    DIRECTION_LEGS = {ascending: :rise, descending: :fall}.freeze

    attr_reader :contour, :pitch_numbers

    def initialize(contour, pitch_numbers)
      @contour = contour
      @pitch_numbers = pitch_numbers
    end

    def degree
      failed_conditions.length
    end

    # Failing to rise (or fall) is failing the direction itself, so it outranks
    # the endpoints.
    def miss
      leg = DIRECTION_LEGS.fetch(contour)
      failed = failed_conditions.include?(leg) ? [leg] : failed_conditions
      "#{contour}_#{failed.join("_and_")}"
    end

    private

    # A wobble too small to make a leg is too small to spoil a direction, and a
    # net change too small to make a leg is too small to make a direction.
    def failed_conditions
      @failed_conditions ||= [
        (:start unless near?(directed.first, directed.min)),
        (:end unless near?(directed.last, directed.max)),
        (DIRECTION_LEGS.fetch(contour) if directed.last - directed.first < TREND_REVERSAL_SEMITONES)
      ].compact
    end

    # Negated for descending, so both directions read as ascending.
    def directed
      @directed ||= (contour == :ascending) ? pitch_numbers : pitch_numbers.map(&:-@)
    end

    def near?(number, extreme)
      (number - extreme).abs < TREND_REVERSAL_SEMITONES
    end
  end
end
