module HeadMusic::MIDI
  # Builds a flow from a decoded sequence in two phases, as the MusicXML and
  # MEI readers do. First the notes become exact records: bars, quantized
  # notes, parts, voices of chords, spellings, and the timeline. Then the
  # flow is built through the shared notation core: the bars aligned in a
  # BarMap, the timeline applied, and each voice placed by VoicePlacer.
  #
  # Model constructors report a value they cannot hold with one of
  # Parser::TRANSLATED, which become ParseErrors in the second phase only,
  # so that a bug in the first escapes as itself.
  class FlowBuilder
    attr_reader :sequence, :budget, :key, :grid

    def initialize(sequence, budget, key: nil, grid: :auto)
      @sequence = sequence
      @budget = budget
      @key = key
      @grid = grid
    end

    def flow
      raise ParseError, "MIDI file contains no notes" if budget.note_count.zero?

      read
      build
    end

    private

    def read
      notes = sequence.notes
      @layout, @quantizer = quantize(notes)
      @parts = PartSource.new(sequence, notes, @quantizer).parts.map { |part| [part, part.voices] }
      Budget.check_voice_bars!(@parts.sum { |_part, voices| voices.length }, @layout.bars.length)
      @timeline = TimelineReader.new(sequence.merged_events, @layout, @quantizer, @quantizer.notes.map(&:onset).uniq.sort)
      spelling = Spelling.new(@parts, @layout, @timeline.key_regions, key: key)
      @pitches = spelling.pitches
      @keys = spelling.keys
    end

    # The layout ends after the latest onset as well as the latest release,
    # so a note struck on the final barline, or snapped to it, has a bar.
    def quantize(notes)
      layout = lay_out(budget.end_tick)
      quantizer = quantizer(layout, notes, grid)
      latest = quantizer.notes.map(&:onset).max
      return [layout, quantizer] if latest < layout.end_time

      grid = quantizer.grid
      layout = lay_out(((latest + grid) * division * 4).ceil)
      Budget.check_bars!(layout.bars.length)
      [layout, quantizer(layout, notes, grid)]
    end

    def lay_out(end_tick)
      BarLayout.new(budget.time_signatures, division: division, end_tick: end_tick)
    end

    def quantizer(layout, notes, grid)
      Quantizer.new(layout, notes, division: division, grid: grid)
    end

    def division
      sequence.division
    end

    def build
      measures = PartReading.measures(@layout)
      bar_map = HeadMusic::Notation::BarMap.new([PartReading.new(measures)])
      flow = HeadMusic::Content::Flow.new(name: sequence.name, **@timeline.opening(@keys))
      @timeline.apply(flow, @keys)
      values = NoteValues.new(@layout)
      events_by_part = @parts.to_h do |part, voices|
        reading = PartReading.new(measures, layout: @layout, values: values, voices: voices.map { |chords| notes(part, chords) }, label: part.key.to_s)
        [part.key, place(add_part(flow, part), reading, bar_map)]
      end
      LyricAttacher.new(lyrics, events_by_part).attach
      flow
    rescue *Parser::TRANSLATED => error
      raise ParseError, error.message
    end

    def add_part(flow, part)
      flow.add_part(player: part.player, instrument: part.instrument).tap do |flow_part|
        part.instrument_changes.each { |bar_number, instrument| flow_part.change_instrument(bar_number, instrument) }
      end
    end

    def notes(part, chords)
      chords.map { |chord| [chord.onset, chord.release, sounds(part, chord)] }
    end

    def sounds(part, chord)
      return @pitches.fetch(chord) unless part.percussion?

      chord.keys.map { |key| part.sound(key) }
    end

    # The first voice spans the flow; later ones leave out their whole bars
    # of rest at either edge. Answers each voice's note events by onset.
    def place(part, reading, bar_map)
      reading.tracks.each_with_index.map do |track, index|
        HeadMusic::Notation::VoicePlacer.new(part.add_voice, track, bar_map, reading, tuplet_reader: PartReading::NoTuplets, trim_edges: index.positive?).place
        track.events.reject(&:rest?).to_h { |event| [@layout.bars[event.measure_index].start + event.cursor, event.voice_event] }
      end
    end

    def lyrics
      sequence.indexed_events.filter_map do |track_index, event|
        next unless event.is_a?(Text) && event.kind == :lyric

        [PartKey.new(track: track_index, channel: nil), @quantizer.snap(event.tick), event.text]
      end
    end
  end
end
