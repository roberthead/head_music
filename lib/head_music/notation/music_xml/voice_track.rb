# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # One <voice> of a part as the part reader collects it: its notes and
  # rests in document order, each at the measure and cursor it was read at,
  # placed on a voice only once every part's bars are known.
  #
  # The cursor follows <duration>s, which exporters round, so each event
  # also keeps the tolerance of one division in force where it was read.
  class VoiceTrack
    # A continuation is a later link of a tie, folded into the event its
    # chain began with, from link_offset on; it is not placed. The voice
    # event is the one placed for its chain.
    Event = Struct.new(
      :measure_index, :cursor, :tolerance, :rhythmic_value, :duration, :sounds, :fills_bar, :cue,
      :tie_starts, :tie_stops, :continuation, :link_offset, :link_count, :voice_event
    ) do
      def head
        continuation || self
      end

      # The links of its chain this event's own written value spans.
      def first_link
        link_offset.to_i
      end

      def last_link
        first_link + link_count - 1
      end

      def rest?
        sounds.empty?
      end

      def ties_out?
        !rest? && sounds.all? { |sound| tie_starts.include?(sound.to_s) }
      end

      def ties_in?
        !rest? && sounds.all? { |sound| tie_stops.include?(sound.to_s) }
      end
    end

    # A <tuplet> start or stop on an event, in document order, with the
    # <normal-type> and dots of its <time-modification>.
    TupletMark = Data.define(:event, :type, :normal_type, :normal_dots)

    attr_reader :label, :events, :tuplet_marks

    def initialize(label)
      @label = label
      @events = []
      @tuplet_marks = []
    end

    def add(**attributes)
      Event.new(**attributes).tap do |event|
        event.link_count = event.rhythmic_value&.tied_chain&.length || 1
        @events << event
      end
    end
  end
end
