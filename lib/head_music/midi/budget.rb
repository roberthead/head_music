module HeadMusic::MIDI
  # The most a file may ask a flow to hold, counted arithmetically from the
  # decoded sequence before any bars, voices, or flow are allocated.
  class Budget
    MAX_NOTES = 200_000
    MAX_BARS = 10_000
    MAX_PARTS = 128
    MAX_VOICES_PER_PART = 64
    MAX_VOICE_BARS = 1_000_000

    # Raised as the separator opens a voice, so that its first fit never
    # searches more than the cap.
    def self.check_voices!(part_key, count)
      return if count <= MAX_VOICES_PER_PART

      raise UnsupportedFeatureError, "#{part_key} needs more than #{MAX_VOICES_PER_PART} voices"
    end

    def self.check_bars!(count)
      return if count <= MAX_BARS

      raise ParseError, "the file needs #{count} bars, more than #{MAX_BARS}"
    end

    def self.check_voice_bars!(voices, bars)
      return if voices * bars <= MAX_VOICE_BARS

      raise ParseError, "#{voices} voices across #{bars} bars are more than #{MAX_VOICE_BARS} voice-bars"
    end

    attr_reader :sequence

    def initialize(sequence)
      @sequence = sequence
    end

    def check!
      check(note_count, MAX_NOTES, "notes")
      check(part_count, MAX_PARTS, "parts")
      self.class.check_bars!(bar_count)
      self
    end

    def note_count
      @note_count ||= sequence.tracks.sum { |track| track.notes.length }
    end

    # Each track and channel with notes, and each later track of format 1
    # that names a part or sets a program without playing a note.
    def part_count
      @part_count ||= begin
        keys = sequence.tracks.flat_map { |track| track.notes.map { |note| PartKey.for(note) } }.uniq.length
        keys + sequence.tracks.drop(1).count { |track| silent_part?(track) }
      end
    end

    # Each run of one meter needs as many bars as its ticks fill, or begin.
    def bar_count
      @bar_count ||= begin
        changes = BarLayout.new(time_signatures, division: sequence.division, end_tick: end_tick).meter_changes
        bars = changes.each_cons(2).sum { |(from, meter), (to, _following)| bars_between(from, to, meter) }
        from, meter = changes.last
        [bars + bars_between(from, Rational(end_tick, sequence.division * 4), meter), 1].max
      end
    end

    def time_signatures
      @time_signatures ||= sequence.merged_events.grep(TimeSignature).freeze
    end

    # The latest release, or the latest event but an end of track.
    def end_tick
      @end_tick ||= sequence.tracks.flat_map { |track| [track.notes.map(&:off).max, last_tick(track)] }.compact.max || 0
    end

    private

    def check(count, limit, things)
      raise ParseError, "the file needs #{count} #{things}, more than #{limit}" if count > limit
    end

    def last_tick(track)
      track.events.reverse_each.find { |event| !event.is_a?(EndOfTrack) }&.tick
    end

    def silent_part?(track)
      sequence.format == 1 && track.notes.empty? && (track.name || track.program_changes.any?)
    end

    def bars_between(from, to, meter)
      return 0 unless to > from

      ((to - from) / BarLayout.length(meter)).ceil
    end
  end
end
