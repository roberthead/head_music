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
      nil
    end
  end
end
