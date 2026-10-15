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
    # chain began with; it is not placed.
    Event = Struct.new(
      :measure_index, :cursor, :tolerance, :rhythmic_value, :duration, :sounds, :fills_bar, :cue,
      :tie_starts, :tie_stops, :continuation
    ) do
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

    attr_reader :label, :events

    def initialize(label)
      @label = label
      @events = []
    end

    def add(**attributes)
      Event.new(**attributes).tap { |event| @events << event }
    end
  end
end
