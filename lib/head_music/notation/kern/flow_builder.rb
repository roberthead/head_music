# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Replays a Document's rows onto a fresh flow.
  #
  # Rows are read in order, so an interpretation is in force before the
  # bar it governs. Each data row is a time slice: every note it attacks
  # must begin exactly when the previous note in its spine ends, and a
  # null token must fall inside a note that is still sounding. Voice events
  # wait until the end, when every bar's number and start are known.
  class FlowBuilder
    attr_reader :document

    def initialize(document)
      @document = document
    end

    def flow
      @built ||= build
    end

    private

    attr_reader :clock

    def build
      @tags = SpineTags.new(document.kern_tracks)
      @flow = nil
      @clock = BarClock.new { |bar_number| @flow.meter_at(bar_number) }
      @timeline = TimelineReader.new(clock)
      @voices = SpineVoices.new
      @dynamics = DynamicPlacer.new(@voices)
      document.rows.each { |row| read(row) }
      raise ParseError, "kern input contains no music" unless @flow

      finish
    end

    def finish
      time = @voices.current_time
      @dynamics.pass(time)
      clock.finish(time, document.rows.last.line)
      @voices.place(clock)
      @dynamics.place(@flow, clock)
      clock.mark(@flow)
      @parts.order_voices_by_staff
      @flow
    end

    def read(row)
      case row.record.kind
      when :interpretation then read_interpretations(row)
      when :barline then read_barline(row)
      when :data then read_data(row)
      end
    end

    # Interpretations

    def read_interpretations(row)
      line = row.line
      time = @voices.current_time
      interpretations = row.kern_fields.filter_map do |track, field, _column|
        interpretation = InterpretationReader.read(field, line_number: line)
        [track, interpretation] if interpretation
      end
      sections, interpretations = interpretations.partition { |_track, interpretation| interpretation.kind == :section }
      clock.section_label(sections.first.last.value, time) if sections.any?
      timeline, spine = interpretations.partition { |_track, interpretation| TimelineReader.timeline?(interpretation) }
      @timeline.read(timeline.map(&:last), time, line)
      @flow ? @spine_changes.read(spine, time, line) : @tags.read(spine, line)
      apply_manipulations(row)
    end

    def apply_manipulations(row)
      row.manipulations.each do |manipulation|
        tracks = manipulation.tracks
        next unless tracks.first.kern?

        @tags.split(*tracks) if manipulation.type == :split
        @voices.manipulate(manipulation, row.line) if @flow
      end
    end

    # The flow

    def start_flow(row)
      citation = CitationReader.new(document)
      work = citation.work
      @flow = @timeline.open_flow(name: document.title, work: work, composer: work ? nil : citation.composer)
      @parts = PartRoster.new(@flow)
      @spine_changes = SpineChanges.new(voices: @voices, parts: @parts, tags: @tags, clock: clock)
      PartGrouping.new(row.tracks.select(&:kern?), @tags).parts.each do |plan|
        @parts.add(plan) { |track, part, staff| @voices.start(track, part, staff) }
      end
    end

    # Data and barlines

    # A grace note takes no time, but its row is timed: it sits at the time
    # of the note it leads to, so it bounds the rows that split the time.
    def read_data(row)
      start_flow(row) unless @flow
      line = row.line
      tokens = row.kern_fields.map { |track, field, column| [track, TokenReader.read(field, line_number: line), column] }
      row_tokens = tokens.map { |_track, token, _column| token }
      attacked = row_tokens.any?(&:attack?)
      return read_untimed(row) unless attacked || row_tokens.any? { |token| token.type == :grace }

      clock.ensure_music_allowed if attacked
      time = @voices.current_time
      events = @voices.read(tokens, time, line)
      LyricReader.new(row).sing(events)
      @dynamics.read(row, events, time)
    end

    def read_untimed(row)
      LyricReader.new(row).sing({})
      @dynamics.read_untimed(row)
    end

    def read_barline(row)
      fields = row.kern_fields
      return if fields.empty?

      line = row.line
      barline = BarlineReader.read(fields.first[1], line_number: line)
      time = @voices.aligned_time(clock, line)
      @dynamics.pass(time)
      clock.barline(barline, time, line)
    end
  end
end
