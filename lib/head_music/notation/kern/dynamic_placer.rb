# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Gives the dynamics and hairpins of a file's **dynam spines to their parts.
  #
  # A level waits for the bars to be final, then goes to its part at its
  # position. An accent goes to every note of its part attacked on its
  # row, or to none.
  #
  # A row that attacks nothing has no time of its own. By Humdrum
  # convention, such rows split the time between the timed rows around
  # them evenly, which is how a level falls in the middle of a note. Their
  # levels wait for the next timed row, an attack or a barline, to be timed.
  #
  # Hairpin marks are timed as levels are, except that a close at its row's
  # end takes the next row's time. Each **dynam spine pairs its own marks,
  # as Verovio does: an open hairpin ends only at a close of its kind, and
  # is dropped at a level, accent, text, or new open before that close.
  class DynamicPlacer
    TimedMark = Struct.new(:mark, :part, :time)

    def initialize(voices)
      @voices = voices
      @levels = []
      @untimed_rows = []
      @marks = []
      @awaiting_row_end = []
      @timed_at = 0
    end

    def read(row, events, time)
      pass(time)
      reader = DynamicReader.new(row)
      reader.dynamics.each do |reading|
        part = @voices.part(reading.track)
        if reading.dynamic.level?
          @levels << [time, part, reading.dynamic]
        else
          accent(events, part, reading.dynamic)
        end
      end
      time_row(row_marks(reader), time)
    end

    # An accent on such a row has no note attacking under it, so it is dropped.
    def read_untimed(row)
      reader = DynamicReader.new(row)
      levels = reader.dynamics.select { |reading| reading.dynamic.level? }
        .map { |reading| [@voices.part(reading.track), reading.dynamic] }
      @untimed_rows << [levels, row_marks(reader)]
    end

    def pass(time)
      step = Rational(time - @timed_at, @untimed_rows.length + 1)
      @untimed_rows.each.with_index(1) do |(levels, marks), index|
        row_time = @timed_at + step * index
        levels.each { |part, level| @levels << [row_time, part, level] }
        time_row(marks, row_time)
      end
      @awaiting_row_end.each { |timed_mark| timed_mark.time = time }
      @awaiting_row_end = []
      @untimed_rows = []
      @timed_at = time
    end

    # A part with a **dynam spine beside each staff often states one level
    # in both, so the first at a position is kept. The time of the last pass
    # is where the music ends, so a hairpin ending there ends on the final
    # barline.
    def place(flow, clock)
      placed = Set.new
      @levels.each do |time, part, level|
        position = position_at(flow, clock, time)
        part.place_dynamic(position, level) if placed.add?([part, position])
      end
      @marks.group_by { |timed_mark| timed_mark.mark.spine }.each_value { |marks| pair(flow, clock, marks) }
    end

    private

    def row_marks(reader)
      reader.hairpin_marks.map { |mark| TimedMark.new(mark, @voices.part(mark.track), nil) }
    end

    def time_row(marks, time)
      @awaiting_row_end.each { |timed_mark| timed_mark.time = time }
      @awaiting_row_end, timed = marks.partition { |timed_mark| timed_mark.mark.role == :close_at_row_end }
      timed.each { |timed_mark| timed_mark.time = time }
      @marks.concat(marks)
    end

    def pair(flow, clock, marks)
      open = nil
      marks.each do |timed_mark|
        case timed_mark.mark.role
        when :interrupt then open = nil
        when :open then open = timed_mark
        else
          next unless open && open.mark.kind == timed_mark.mark.kind

          add_hairpin(flow, clock, open, timed_mark)
          open = nil
        end
      end
    end

    # A zero-length hairpin, or one overlapping a hairpin already read from
    # another of the part's spines, is dropped; the same hairpin from both
    # spines is kept once.
    def add_hairpin(flow, clock, open, close)
      from = position_at(flow, clock, open.time)
      to = (close.time >= @timed_at) ? flow.final_barline_position : position_at(flow, clock, close.time)
      open.part.add_span(open.mark.kind, from: from, to: to)
    rescue ArgumentError
      nil
    end

    def position_at(flow, clock, time)
      bar = clock.bar_containing(time)
      HeadMusic::Notation::BarSplitter.position_at(flow, bar.number, time - bar.start)
    end

    # A note's own sforzando, written in its token, outranks the spine's.
    def accent(events, part, dynamic)
      events.each do |track, event|
        next if event.nil? || event.pitches.empty? || !@voices.part(track).equal?(part)

        event.note_dynamic ||= dynamic.name_key
      end
    end
  end
end
