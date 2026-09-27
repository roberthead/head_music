# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Gives the dynamics of a file's **dynam spines to their parts.
  #
  # A level waits for the bars to be final, then goes to its part at its
  # position. An accent goes to every note of its part attacked on its
  # row, or to none.
  class DynamicPlacer
    def initialize(voices)
      @voices = voices
      @levels = []
    end

    def read(row, events, time)
      DynamicReader.new(row).dynamics.each do |reading|
        part = @voices.part(reading.track)
        if reading.dynamic.level?
          @levels << [time, part, reading.dynamic]
        else
          accent(events, part, reading.dynamic)
        end
      end
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
