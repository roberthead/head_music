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

    def initialize(track, reading, bar_map)
      @track = track
      @reading = reading
      @bar_map = bar_map
    end

    def apply
      chain = nil
      @track.events.each do |event|
        head = chain&.first
        joined = head && event.ties_in? && follows?(chain.last, event)
        if joined && keys(head) == keys(event)
          link(chain, event)
          next if event.ties_out?

          chain = finish(chain)
        elsif joined && !keys(head).intersect?(keys(event))
          raise_unrelated(head, event)
        else
          finish(chain)
          chain = event.ties_out? ? [event] : nil
        end
      end
      finish(chain)
    end

    private

    def raise_unrelated(head, event)
      raise @reading.errors::ParseError.new(
        "A tie connects #{keys(head).join(" ")} to #{keys(event).join(" ")}", **@reading.where(head.measure_index)
      )
    end

    def link(chain, event)
      head = chain.first
      @links = head.rhythmic_value.tied_chain.length if chain.one?
      event.link_offset = @links
      @links += event.rhythmic_value.tied_chain.length
      event.continuation = head
      chain << event
    end

    # The head takes its chain's values once every link is known, since
    # appending each link in turn rebuilds the chain so far.
    def finish(chain)
      return if chain.nil? || chain.one?

      chain.first.rhythmic_value = chain.map(&:rhythmic_value).reverse.reduce { |tail, value| value.append_tied(tail) }
      nil
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
