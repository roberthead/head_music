# A module for visual music notation
module HeadMusic::Notation
  # Folds tied notes into one event, in one pass over a track. An event
  # whose every pitch starts a tie takes in the next event whose every pitch
  # stops one, appending its value to the chain, across any number of
  # barlines, and keeping each link's written spelling.
  #
  # A tie that nothing stops, as one opening in a first ending and closing
  # in the second, or one followed by a rest, is dropped, and its note keeps
  # its written value, as is a tie whose stop does not start where the link
  # before it ends, within a division. Within a chord, a tie on only some
  # of its pitches is skipped, so those notes are struck again, as is a tie
  # between chords that share only some of their pitches. A tie between
  # pitches that share nothing raises, naming the measure it starts in.
  class TieFolding
    def self.apply(track, reading, bar_map)
      new(track, reading, bar_map).apply
    end

    # Ties each track's grace notes, then folds its ties.
    def self.apply_to_readings(readings, bar_map)
      readings.each do |reading|
        reading.tracks.each do |track|
          track.tie_graces
          apply(track, reading, bar_map)
        end
      end
    end

    def initialize(track, reading, bar_map)
      @track = track
      @reading = reading
      @bar_map = bar_map
    end

    def apply
      chain = nil
      @track.events.each do |event|
        if joins?(chain, event)
          link(chain, event)
        else
          finish(chain)
          chain = [event]
        end
        next if event.ties_out?

        chain = finish(chain)
      end
      finish(chain)
    end

    private

    # Whether an event continues the chain, raising where the tie into it
    # connects pitches the chain's head shares nothing with.
    def joins?(chain, event)
      return false unless chain && event.ties_in? && follows?(chain.last, event)

      head_keys = chain.first.keys
      keys = event.keys
      raise_unrelated(chain.first, event) unless head_keys.intersect?(keys)
      head_keys == keys
    end

    def raise_unrelated(head, event)
      raise @reading.errors::ParseError.new(
        "A tie connects #{head.keys.join(" ")} to #{event.keys.join(" ")}", **@reading.where(head.measure_index)
      )
    end

    def link(chain, event)
      event.link_offset = chain.sum(&:link_count)
      event.continuation = chain.first
      chain << event
    end

    # The head takes its chain's values once every link is known, since
    # appending each link in turn rebuilds the chain so far.
    def finish(chain)
      return if chain.nil? || chain.one?

      chain.first.rhythmic_value = DottedDuration.tied(chain.map(&:rhythmic_value))
      nil
    end

    def follows?(link, event)
      link_end = @bar_map.time_of(link.measure_index, link.cursor + link.duration)
      (@bar_map.time_of(event.measure_index, event.cursor) - link_end).abs < event.tolerance
    end
  end
end
