module HeadMusic::MIDI
  # Turns the notes of every track into note ons and offs, so that a key is
  # never struck twice on a channel while it sounds. A note that begins while
  # its channel's key is held releases the held one and strikes again, then
  # sounds until the later release; notes struck at once sound as one. A
  # channel may be shared by several tracks, so this works across them, and a
  # release that a strike in another track meets is written in that track,
  # since a player orders events of one tick only within a track.
  class KeyOverlaps
    # Times are ticks; +track+ is the index of the part's track.
    Sounding = Data.define(:track, :channel, :key, :on, :off, :velocity)

    def initialize(soundings)
      @soundings = soundings
    end

    # [track, event] pairs.
    def events
      @soundings.group_by { |sounding| [sounding.channel, sounding.key] }.each_value.flat_map do |group|
        resolve(group.each_with_index.sort_by { |sounding, index| [sounding.on, index] }.map(&:first))
      end
    end

    private

    def resolve(group)
      events = []
      held = group.first
      group.drop(1).each do |sounding|
        if sounding.on == held.on
          held = held.with(off: [held.off, sounding.off].max)
        else
          release_at = [held.off, sounding.on].min
          events.concat(note(held, release_at, (release_at == sounding.on) ? sounding.track : held.track))
          held = sounding.with(off: [held.off, sounding.off].max)
        end
      end
      events.concat(note(held, held.off, held.track))
    end

    def note(sounding, release_at, release_track)
      [
        [sounding.track, NoteOn.new(sounding.on, sounding.channel, sounding.key, sounding.velocity)],
        [release_track, NoteOff.new(tick: release_at, channel: sounding.channel, key: sounding.key)]
      ]
    end
  end
end
