# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Gives the dynamics of a file's **dynam spines to their parts.
  #
  # A level waits for the bars to be final, then goes to its part at its
  # position. An accent goes to every note of its part attacked on its
  # row, or to none.
  #
  # A row that attacks nothing has no time of its own. By Humdrum
  # convention, such rows split the time between the timed rows around
  # them evenly, which is how a level falls in the middle of a note. Their
  # levels wait for the next timed row, an attack or a barline, to be timed.
  class DynamicPlacer
    def initialize(voices)
      @voices = voices
      @levels = []
      @untimed_levels = []
      @timed_at = 0
    end

    def read(row, events, time)
      pass(time)
      DynamicReader.new(row).dynamics.each do |reading|
        part = @voices.part(reading.track)
        if reading.dynamic.level?
          @levels << [time, part, reading.dynamic]
        else
          accent(events, part, reading.dynamic)
        end
      end
    end

    # An accent on such a row has no note attacking under it, so it is dropped.
    def read_untimed(row)
      @untimed_levels << DynamicReader.new(row).dynamics.select { |reading| reading.dynamic.level? }
        .map { |reading| [@voices.part(reading.track), reading.dynamic] }
    end

    def pass(time)
      step = Rational(time - @timed_at, @untimed_levels.length + 1)
      @untimed_levels.each.with_index(1) do |levels, index|
        levels.each { |part, level| @levels << [@timed_at + step * index, part, level] }
      end
      @untimed_levels = []
      @timed_at = time
    end

    # A part with a **dynam spine beside each staff often states one level
    # in both, so the first at a position is kept.
    def place(flow, clock)
      placed = Set.new
      @levels.each do |time, part, level|
        bar = clock.bar_containing(time)
        position = HeadMusic::Notation::BarSplitter.position_at(flow, bar.number, time - bar.start)
        part.place_dynamic(position, level) if placed.add?([part, position])
      end
    end

    private

    # A note's own sforzando, written in its token, outranks the spine's.
    def accent(events, part, dynamic)
      events.each do |track, event|
        next if event.nil? || event.pitches.empty? || !@voices.part(track).equal?(part)

        event.note_dynamic ||= dynamic.name_key
      end
    end
  end
end
