module HeadMusic::MIDI
  # The meter, tempo, and key in force at each downbeat, read in one sweep
  # of the bars against the file's meta events, each snapped as an onset is.
  # The flow opens with the first bar's, and changes at a later downbeat
  # only where one differs from the bar before.
  #
  # A tempo applies from the first downbeat at or after it, so a change
  # within a bar is skipped. A key signature within a bar applies at its
  # downbeat when no note starts before it there, and otherwise at the next.
  class TimelineReader
    DEFAULT_MICROSECONDS = 500_000
    MAX_DECIMALS = 3

    # A tempo of so many microseconds a quarter, in the meter's beat, with
    # the fewest decimals that write back the same microseconds. A very slow
    # tempo rounds to 0 at too few decimals, which writes back nothing.
    def self.tempo(microseconds, meter)
      beat = BarLayout.beat(meter)
      exact = Rational(60_000_000) / (microseconds * beat.fraction * 4)
      tempos = (0..MAX_DECIMALS).lazy.map { |digits| exact.round(digits) }.select(&:positive?).map { |bpm| HeadMusic::Rudiment::Tempo.new(beat, bpm) }
      tempos.find { |tempo| Tempo.microseconds_per_quarter(tempo) == microseconds } || tempos.to_a.last
    end

    attr_reader :layout

    # +events+ are the sequence's merged events; +onsets+ every quantized
    # onset, sorted and unique.
    def initialize(events, layout, quantizer, onsets)
      @events = events
      @layout = layout
      @quantizer = quantizer
      @onsets = onsets
    end

    # The file's key signatures as KeyRegions at the downbeats they take
    # effect on, each differing from the one before. Before the first, the
    # key is C major, as the SMF specification says.
    def key_regions
      @key_regions ||= begin
        keys = keys_by_bar
        first = layout.bars.first
        keys = {first => [0, false]}.merge(keys) unless keys.empty? || keys.key?(first)
        ChangeCursor.changes(keys).map { |bar, key| region(bar, *key) }
      end
    end

    # +keys+ are the KeyRegions the flow's signatures come from, the first
    # opening it.
    def opening(keys)
      first = layout.bars.first
      {meter: first.meter, tempo: tempo_at(first), key_signature: keys.first&.key&.name}
    end

    def apply(flow, keys)
      layout.bars.each_cons(2) do |before, bar|
        flow.change_meter(bar.number, bar.meter) unless bar.meter == before.meter
        flow.change_tempo(bar.number, tempo_at(bar)) if tempos.key?(bar.number)
      end
      keys.drop(1).each { |region| flow.change_key_signature(region.bar_number, region.key.name) }
    end

    private

    def tempo_at(bar)
      self.class.tempo(tempos.fetch(bar.number), bar.meter)
    end

    def region(bar, fifths, minor)
      key = HeadMusic::Notation::MusicXML::KeyMapper.tonal_context(fifths, minor ? "minor" : "major")
      HeadMusic::Analysis::KeyRegion.new(bar_number: bar.number, onset: bar.start, key: key)
    end

    # {bar number => microseconds} at the first bar and wherever it changes.
    def tempos
      @tempos ||= begin
        changes = ChangeCursor.new(timed(Tempo), &:first)
        microseconds = layout.bars.map { |bar| [bar.number, changes.at(bar.start)&.last&.microseconds_per_quarter || DEFAULT_MICROSECONDS] }
        ChangeCursor.changes(microseconds).to_h
      end
    end

    # {Bar => [fifths, minor]} in bar order, the last at a bar winning.
    def keys_by_bar
      timed(KeySignature).each_with_object({}) do |(time, event), by_bar|
        bar = downbeat_for(time)
        by_bar[bar] = [event.fifths, event.minor] if bar
      end
    end

    def downbeat_for(time)
      bar = layout.bar_at(time)
      return if time >= bar.end_time
      return bar if time <= bar.start || !onset_between?(bar.start, time)

      layout.bars[bar.number - layout.first_number + 1]
    end

    def onset_between?(from, to)
      onset = @onsets.bsearch { |candidate| candidate >= from }
      !onset.nil? && onset < to
    end

    # [snapped time, event] for each event of a kind, in merged order.
    def timed(kind)
      @events.grep(kind).map { |event| [@quantizer.snap(event.tick), event] }
    end
  end
end
