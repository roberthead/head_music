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
      :tie_starts, :tie_stops, :continuation, :link_offset, :link_count, :voice_event, :graces, :staff
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

    # A grace note waiting for the main note it leads to, and whether it is
    # tied to whatever follows it.
    Grace = Struct.new(:sounds, :rhythmic_value, :slashed, :articulations, :tie_starts, :tied)

    # A <tuplet> start or stop on an event, in document order, with the
    # <normal-type> and dots of its <time-modification>.
    TupletMark = Data.define(:event, :type, :normal_type, :normal_dots)

    attr_reader :label, :events, :tuplet_marks, :queued_graces

    def initialize(label)
      @label = label
      @events = []
      @tuplet_marks = []
      @queued_graces = []
    end

    # A main note takes every grace note queued since the one before it.
    def add(**attributes)
      Event.new(**attributes).tap do |event|
        event.link_count = event.rhythmic_value&.tied_chain&.length || 1
        event.graces = @queued_graces
        @queued_graces = []
        @events << event
      end
    end

    def queue_grace(**attributes)
      Grace.new(**attributes, tied: false).tap { |grace| @queued_graces << grace }
    end

    # A grace note is tied to each pitch it starts a tie on that what
    # follows it shares, the next grace note or the main note, and a tie
    # into the main note takes the place of the stop it carries, so that
    # the main note ends no chain. Answers the grace notes still queued at
    # the end of the part, which lead to nothing and are dropped.
    def tie_graces
      @events.each do |event|
        event.graces.each_with_index do |grace, index|
          follower = event.graces[index + 1]&.sounds || event.sounds
          shared = grace.tie_starts & follower.map(&:to_s)
          grace.tied = shared.any?
          event.tie_stops -= shared if grace.equal?(event.graces.last)
        end
      end
      @queued_graces
    end
  end
end
