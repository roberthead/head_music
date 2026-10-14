# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # The <wedge> numbers of one part's hairpins, its own and its voices'.
  #
  # Readers pair wedges by number in document order, as they do slurs, so the
  # numbers are given walking the part's DirectionPlan: a stop frees its
  # number and a start takes the lowest free one. A stop at a position is
  # written before a start there, so one wedge can end where the next begins
  # on the same number. MusicXML numbers wedges from 1 to 16.
  class WedgeNumbers
    LIMIT = 16

    def initialize(part, plan)
      @numbers = {}.compare_by_identity
      @in_use = {}
      walk(plan.direction_plan(part))
    end

    def number(span)
      @numbers.fetch(span)
    end

    private

    def walk(direction_plan)
      direction_plan.slots.each do |slot|
        direction_plan.marks(slot).each do |mark|
          stop(mark.item) if mark.type == :stop
          start(mark.item) if mark.type == :start
        end
      end
    end

    def stop(span)
      @in_use.delete(@numbers.fetch(span))
    end

    def start(span)
      number = (1..LIMIT).find { |candidate| !@in_use.key?(candidate) }
      raise RenderError, "MusicXML cannot hold more than #{LIMIT} wedges open at once in a part, at #{span.from}" unless number

      @in_use[number] = span
      @numbers[span] = number
    end
  end
end
