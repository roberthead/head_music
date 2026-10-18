class HeadMusic::Content::VoiceEvent
  # Walks back from a voice event to where its run of one ratio starts, or to
  # one whose remainder is already known, then forward adding exact lengths.
  # Iterative, so that a long run cannot exhaust the stack.
  class Run
    def initialize(voice_event)
      @voice_event = voice_event
    end

    def remainder
      events = candidates
      remainder = events.first.memoized[:onset_remainder] || 0
      events.each_cons(2) do |previous, current|
        remainder = current.memoized[:onset_remainder] = following_remainder(previous, remainder, current)
      end
      remainder
    end

    private

    attr_reader :voice_event

    def candidates
      events = [voice_event]
      loop do
        previous = sharing_predecessor(events.first)
        break unless previous

        events.unshift(previous)
        break if previous.memoized.key?(:onset_remainder)
      end
      events
    end

    def following_remainder(previous, remainder, current)
      carried = remainder + previous.rhythmic_value.exact_subticks
      return 0 unless previous.position.advance(subticks: carried.round) == current.position

      carried - carried.round
    end

    def sharing_predecessor(current)
      ratio = current.rhythmic_value.tuplet_ratio
      return unless ratio

      previous = current.voice.voice_event_preceding(current.position)
      previous if previous && previous.rhythmic_value.tied_chain.last.tuplet_ratio == ratio
    end
  end
end
