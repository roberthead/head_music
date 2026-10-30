# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Counts a voice's notes, chords, and rests into the tuplet a "(p:q:r"
  # marker opens, and groups each tuplet once the voice has placed its notes.
  #
  # Counting hands back the tuplet's ends that the counted note begins or
  # ends, each as [tuplet, edge, links]: links is the count of tied links
  # ahead of the end in the note's chain, or nil for the end of the chain so
  # far, since a pending note may yet have links tied onto it.
  class TupletGrouping
    OpenTuplet = Struct.new(:ratio, :owed, :from, :to, :started)

    def initialize(voice)
      @voice = voice
      @closed = []
    end

    def open(marker, line)
      if @tuplet
        raise UnsupportedFeatureError.new(
          "Unsupported ABC feature: nested tuplets", line_number: line, snippet: "(#{marker.actual}"
        )
      end

      ratio = marker.ratio
      @tuplet = OpenTuplet.new(ratio, marker.count) if ratio
    end

    # A tuplet still owed notes when its voice ends is left ungrouped, its
    # notes keeping their ratio.
    def close
      @tuplet = nil
      group_closed
      @closed.clear
    end

    # The ratio for the next note, chord, or rest, and the ends it marks.
    def count
      tuplet = @tuplet
      return [nil, []] unless tuplet

      ends = []
      ends << [tuplet, :from, nil] unless tuplet.started
      tuplet.started = true
      tuplet.owed -= 1
      ends << close_counted(tuplet) if tuplet.owed.zero?
      [tuplet.ratio, ends]
    end

    # When a pending note's chain gains a link, its own ends are fixed at the
    # links counted so far, before the chain grows past them.
    def fix_ends(ends, prefix, chain)
      ends.map { |tuplet, edge, links| [tuplet, edge, links || end_links(edge, prefix, chain)] }
    end

    def place_ends(voice_event, ends, prefix = nil)
      ends.each do |tuplet, edge, links|
        tuplet[edge] = link_position(voice_event, links || end_links(edge, prefix, voice_event.rhythmic_duration))
      end
      group_closed
    end

    # An invisible rest marks its ends where it starts and stops.
    def mark_ends(ends, from, to)
      ends.each { |tuplet, edge, _| tuplet[edge] = (edge == :from) ? from : to }
    end

    # One the voice refuses, such as one whose notes do not fill a plain
    # value, is left ungrouped, its notes keeping their ratio.
    def group_closed
      @closed.reject! do |tuplet|
        from = tuplet.from
        to = tuplet.to
        next false unless from && to && @voice.next_position >= to

        group(from, to)
        true
      end
    end

    private

    def close_counted(tuplet)
      @closed << tuplet
      @tuplet = nil
      [tuplet, :to, nil]
    end

    def end_links(edge, prefix, chain)
      (edge == :from) ? (prefix&.values&.length || 0) : chain.values.length
    end

    def link_position(voice_event, index)
      links = HeadMusic::Content::TupletGroup.links_of(voice_event)
      (index == links.length) ? voice_event.next_position : links[index].start_position
    end

    def group(from, to)
      @voice.group_tuplet(from: from, to: to)
    rescue ArgumentError
      nil
    end
  end
end
