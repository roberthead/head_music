module HeadMusic
  module Notation
    # Places a voice's dynamic events on its voice events, for writers that can
    # only write a dynamic on a note or rest. Each dynamic goes on the first
    # voice event at or after its position, so one that falls in the middle
    # of a note is written before the next one, and one with nothing after it
    # is left out. Where two land on one voice event, the later wins, and at
    # one position the voice's own wins over its part's, as Voice#dynamic_at
    # decides.
    class DynamicPlacement
      def initialize(voice, include_part: false)
        @voice = voice
        @include_part = include_part
      end

      # @return [HeadMusic::Rudiment::Dynamic, nil] the level to write before
      #   the voice event
      def level_for(voice_event)
        levels[voice_event]
      end

      # @return [Hash{VoiceEvent => HeadMusic::Rudiment::Dynamic}] keyed by
      #   identity, in position order
      def levels
        @levels ||= winners.transform_values { |(_position, _rank, level)| level }
      end

      private

      attr_reader :voice

      def winners
        ranked_events.each_with_object({}.compare_by_identity) do |candidate, winners|
          voice_event = target_for(candidate.first)
          next unless voice_event

          current = winners[voice_event]
          winners[voice_event] = candidate if current.nil? || (candidate.first(2) <=> current.first(2)).positive?
        end
      end

      def ranked_events
        events = voice.dynamic_events.map { |event| [event.position, 1, event.level] }
        events += voice.part.dynamic_events.map { |event| [event.position, 0, event.level] } if @include_part
        events
      end

      def target_for(position)
        voice.voice_events.bsearch { |voice_event| voice_event.position >= position }
      end
    end
  end
end
