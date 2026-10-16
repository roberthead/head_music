module HeadMusic::MIDI
  # Sings lyric meta events on the note events they fall on.
  class LyricAttacher
    WHITESPACE = /\A[[:space:]]+|[[:space:]]+\z/

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
      stripped = text.to_s.gsub(WHITESPACE, "")
      [stripped.delete_suffix("-").gsub(WHITESPACE, ""), stripped.end_with?("-")]
    end

    def event_at(part_key, time)
      onsets_by_track.fetch(part_key.track, all_onsets)[time]
    end

    # A lyric's track names its part; a track with no notes names none, so
    # its lyrics may land on any part. The first voice with a note at a
    # time wins.
    def onsets_by_track
      @onsets_by_track ||= @events_by_part.each_with_object({}) do |(key, voices), by_track|
        by_track[key.track] = index(by_track.fetch(key.track, {}), voices)
      end
    end

    def all_onsets
      @all_onsets ||= index({}, @events_by_part.values.flatten(1))
    end

    def index(onsets, voices)
      voices.each { |voice| voice.each { |time, event| onsets[time] = event unless onsets.key?(time) } }
      onsets
    end
  end
end
