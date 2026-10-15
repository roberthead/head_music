module HeadMusic::Notation::MEI
  # Groups a placed voice's tuplets, for VoicePlacer's tuplet_reader:, from
  # the groups TupletSpans found for its track. A group runs from the first
  # link of its first event to the last link of its last, so a bracket
  # ending on the first piece of a tied note groups by link. A group the
  # voice refuses is left ungrouped, its values keeping their ratio.
  class TupletReader
    def initialize(voice, track, reading)
      @voice = voice
      @track = track
      @reading = reading
    end

    def group
      @reading.tuplet_groups.fetch(@track, []).each { |first, last| add_group(first, last) }
    end

    private

    def add_group(first_event, last_event)
      first = link(first_event, first_event.first_link)
      last = link(last_event, last_event.last_link)
      return unless first && last

      @voice.group_tuplet(from: first.start_position, to: last.end_position)
    rescue ArgumentError
      nil
    end

    def link(event, index)
      voice_event = event.head.voice_event
      voice_event && HeadMusic::Content::TupletGroup.links_of(voice_event)[index]
    end
  end
end
