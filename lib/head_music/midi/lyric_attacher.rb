module HeadMusic::MIDI
  # Sings lyric meta events on the note events they fall on.
  class LyricAttacher
    # +lyrics+ are [PartKey, time, text] triples in merged order, each
    # PartKey naming the lyric's track with a nil channel and each time
    # snapped by the quantizer. +events_by_part+ maps each part's key, in
    # part order, to its voices in voice order, each a hash of note events
    # by onset time.
    def initialize(lyrics, events_by_part)
      @lyrics = lyrics
      @events_by_part = events_by_part
    end

    def attach
      verses = Hash.new(0).compare_by_identity
      @lyrics.each do |part_key, time, text|
        syllable, hyphen_after = parse(text)
        next if syllable.empty?

        event = event_at(part_key, time)
        next unless event

        verses[event] += 1
        event.sing(syllable, verse: verses[event], hyphen_after: hyphen_after)
      end
      nil
    end

    private

    def parse(text)
      stripped = text.to_s.strip
      [stripped.delete_suffix("-").strip, stripped.end_with?("-")]
    end

    def event_at(part_key, time)
      candidate_voices(part_key).each do |onsets|
        return onsets[time] if onsets.key?(time)
      end
      nil
    end

    # A lyric's track names its part; a track with no notes names none, so
    # its lyrics may land on any part.
    def candidate_voices(part_key)
      own = @events_by_part.select { |key, _voices| key.track == part_key.track }
      (own.empty? ? @events_by_part : own).values.flatten(1)
    end
  end
end
