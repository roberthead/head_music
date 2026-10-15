# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
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

    def initialize(track, reading, bar_map)
      @track = track
      @reading = reading
      @bar_map = bar_map
    end

    def apply
      open = nil
      last = nil
      @track.events.each do |event|
        joined = open && event.ties_in? && follows?(last, event)
        if joined && keys(open) == keys(event)
          fold(open, event)
          last = event
          open = nil unless event.ties_out?
        elsif joined && !keys(open).intersect?(keys(event))
          raise_unrelated(open, event)
        else
          open = last = event.ties_out? ? event : nil
        end
      end
    end

    private

    def raise_unrelated(head, event)
      measure = @reading.measures[head.measure_index]
      raise ParseError.new(
        "A tie connects #{keys(head).join(" ")} to #{keys(event).join(" ")}", measure: measure.number, part: @reading.id
      )
    end

    def fold(head, event)
      event.link_offset = head.rhythmic_value.tied_chain.length
      head.rhythmic_value = head.rhythmic_value.append_tied(event.rhythmic_value)
      event.continuation = head
    end

    def follows?(link, event)
      link_end = @bar_map.time_of(link.measure_index, link.cursor + link.duration)
      (@bar_map.time_of(event.measure_index, event.cursor) - link_end).abs < event.tolerance
    end

    def keys(event)
      event.sounds.map(&:to_s).sort
    end
  end
end
