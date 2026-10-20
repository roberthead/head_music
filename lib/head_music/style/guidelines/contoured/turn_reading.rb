class HeadMusic::Style::Guidelines::Contoured
  # Reads an arch as a rise to its climax and a fall from it, and a valley as
  # the mirror, so a turn back counts only against the half it interrupts.
  class TurnReading
    MIRRORS = {arch: :valley, valley: :arch}.freeze

    # The legs of each half, in order, for an arch read as written.
    HALF_LEGS = {arch: %i[rise fall], valley: %i[fall rise]}.freeze

    # A half turning back half its headway makes a second hump, which is a wave.
    HALF_RETRACE_SHARE = 0.5

    attr_reader :contour, :pitch_numbers

    def initialize(contour, pitch_numbers)
      @contour = contour
      @pitch_numbers = pitch_numbers
    end

    def degree
      halves.sum(&:degree) + (second_turn? ? 1 : 0)
    end

    def miss
      return "reversed_legs" if TurnReading.new(MIRRORS.fetch(contour), pitch_numbers).degree.zero?

      failed = [0, 1].reject { |index| halves[index].degree.zero? }
      return "extra_legs" if failed.empty?
      return "missing_legs" if failed.length == 2

      index = failed.first
      flaw = halves[index].pitch_numbers.one? ? "missing" : "unsteady"
      "#{flaw}_#{HALF_LEGS.fetch(contour)[index]}"
    end

    private

    # Negated for a valley, so both shapes read as an arch.
    def numbers
      @numbers ||= (contour == :arch) ? pitch_numbers : pitch_numbers.map(&:-@)
    end

    def halves
      @halves ||= [
        DirectionReading.new(:ascending, numbers[..numbers.index(climax)], retrace_share: HALF_RETRACE_SHARE),
        DirectionReading.new(:descending, numbers[numbers.rindex(climax)..], retrace_share: HALF_RETRACE_SHARE)
      ]
    end

    def climax
      numbers.max
    end

    # A repeated climax is one turn only if the line holds near it between.
    def second_turn?
      plateau = numbers[numbers.index(climax)..numbers.rindex(climax)]
      climax - plateau.min >= TREND_REVERSAL_SEMITONES
    end
  end
end
