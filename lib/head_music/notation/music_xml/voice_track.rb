# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # One <voice> of a part as the part reader collects it: its notes and
  # rests in document order, each at the measure and cursor it was read at,
  # placed on a voice only once every part's bars are known.
  #
  # The cursor follows <duration>s, which exporters round, so each event
  # also keeps the tolerance of one division in force where it was read.
  class VoiceTrack
    Event = Struct.new(:measure_index, :cursor, :tolerance, :rhythmic_value, :duration, :sounds, :fills_bar, :cue) do
      def rest?
        sounds.empty?
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
