module HeadMusic::MIDI
  # Names a part by the track and 0-based wire channel its notes came from.
  # A lyric, which has no channel, names its track with a nil channel.
  PartKey = Data.define(:track, :channel) do
    def self.for(note)
      new(track: note.track, channel: note.channel)
    end

    def percussion?
      channel == 9
    end

    # One-based, as sequencers number tracks and channels.
    def to_s
      [("track #{track + 1}" if track), ("channel #{channel + 1}" if channel)].compact.join(", ")
    end
  end
end
