module HeadMusic::MIDI
  # The key signatures a file puts in force, as KeyRegions at the downbeats
  # they take effect on, each differing from the one before. Before the
  # first, the key is C major, as the SMF specification says. A key
  # signature within a bar applies at its downbeat when no note starts
  # before it there, and otherwise at the next.
  class KeyChanges
    # +signatures+ are [snapped time, KeySignature] pairs in merged order.
    def initialize(signatures, layout, onsets)
      @signatures = signatures
      @layout = layout
      @onsets = onsets
    end

    def regions
      keys = keys_by_bar
      first = @layout.bars.first
      keys = {first => [0, false]}.merge(keys) unless keys.empty? || keys.key?(first)
      ChangeCursor.changes(keys).map { |bar, key| region(bar, *key) }
    end

    private

    def region(bar, fifths, minor)
      key = HeadMusic::Notation::MusicXML::KeyMapper.tonal_context(fifths, minor ? "minor" : "major")
      HeadMusic::Analysis::KeyRegion.new(bar_number: bar.number, onset: bar.start, key: key)
    end

    # {Bar => [fifths, minor]} in bar order, the last at a bar winning.
    def keys_by_bar
      @signatures.each_with_object({}) do |(time, event), by_bar|
        bar = downbeat_for(time)
        by_bar[bar] = [event.fifths, event.minor] if bar
      end
    end

    def downbeat_for(time)
      bar = @layout.bar_at(time)
      return if time >= bar.end_time
      return bar if time <= bar.start || !@onsets.between?(bar.start, time, including_from: true)

      @layout.bars[bar.number - @layout.first_number + 1]
    end
  end
end
