module HeadMusic::MIDI
  # One part's track: its name, its program changes, its lyrics, and the
  # notes it sounds, in exact whole notes from the file's start. A note held
  # over a barline sounds on only when the next played bar is the next in the
  # score; otherwise it releases at the barline, and its continuation strikes
  # afresh wherever its bar is played.
  class PartTrack
    Note = Data.define(:channel, :key, :on, :off, :velocity)

    Held = Data.define(:voice_event, :piece, :on, :off)

    attr_reader :part, :timeline, :channel

    def initialize(part, timeline:, channel:, transposed:, lyric_events:)
      @part = part
      @timeline = timeline
      @channel = channel
      @sound_keys = SoundKeys.new(part, channel: channel, transposed: transposed)
      @lyric_events = lyric_events
    end

    def name
      [part.player&.name, part.instrument&.name, part.voices.first&.role].map(&:to_s).find { |name| !name.empty? }
    end

    def meta_events
      events = name ? [Text.new(0, :track_name, name)] : []
      events.concat(program_changes)
      events.concat(lyrics)
    end

    def notes
      @notes ||= begin
        @sounded = []
        @held = {}
        timeline.spans.each_with_index { |span, index| sound_span(span, index) }
        @sounded + @held.values.flat_map { |held| strike(held) }
      end
    end

    private

    def program_changes
      return [] unless channel

      ProgramChanges.new(part, timeline).changes.map { |time, program| ProgramChange.new(time, channel, program) }
    end

    def lyrics
      timeline.spans.flat_map do |span|
        onsets_in(span.bar_number).filter_map do |voice_event, offset|
          next if offset < span.window_from

          text = @lyric_events.text_for(voice_event, span.pass)
          Text.new(span.time_at(offset), :lyric, text) if text
        end
      end
    end

    def sound_span(span, index)
      touched = []
      pieces_in(span.bar_number).each do |voice_event, piece, bar_piece|
        from = [bar_piece.from, span.window_from].max
        next unless bar_piece.to > from

        key = [voice_event, piece.id]
        touched << key
        held = (bar_piece.joins_previous && @held[key]) || Held.new(voice_event, piece, span.time_at(from), nil)
        @held[key] = held.with(off: span.time_at(bar_piece.to))
        release(key) unless bar_piece.continues && timeline.continues_after?(index)
      end
      (@held.keys - touched).each { |key| release(key) }
    end

    def release(key)
      @sounded.concat(strike(@held.delete(key)))
    end

    def strike(held)
      held.piece.sounds.map do |sound|
        channel, key = @sound_keys.for(sound, held.voice_event.position.bar_number)
        Note.new(channel, key, held.on, held.off, held.piece.velocity)
      end
    end

    def pieces_in(bar_number)
      pieces_by_bar.fetch(bar_number, [])
    end

    def pieces_by_bar
      @pieces_by_bar ||= part.voices.each_with_object({}) do |voice, by_bar|
        resolver = VelocityResolver.new(voice)
        voice.note_events.each do |voice_event|
          NoteTiming.new(voice_event, resolver).pieces.each do |piece|
            BarPieces.of(voice_event, piece.from, piece.to).each do |bar_piece|
              (by_bar[bar_piece.bar_number] ||= []) << [voice_event, piece, bar_piece]
            end
          end
        end
      end
    end

    def onsets_in(bar_number)
      @onsets_by_bar ||= part.voices.flat_map(&:note_events).group_by { |voice_event|
        HeadMusic::Notation::BarSplitter.exact_start(voice_event).first
      }.transform_values { |voice_events|
        voice_events.map { |voice_event| [voice_event, HeadMusic::Notation::BarSplitter.exact_start(voice_event).last] }
      }
      @onsets_by_bar.fetch(bar_number, [])
    end
  end
end
