# A module for visual music notation
module HeadMusic::Notation
  # One voice of a part as a reader collects it: its notes and rests in
  # document order, each at the measure and cursor it was read at, placed on
  # a voice only once every part's bars are known.
  #
  # The cursor follows the durations read, which exporters may round, so
  # each event also keeps the tolerance of one division in force where it
  # was read.
  class VoiceTrack
    # A continuation is a later link of a tie, folded into the event its
    # chain began with, from link_offset on; it is not placed. The voice
    # event is the one placed for its chain.
    Event = Struct.new(
      :measure_index, :cursor, :tolerance, :rhythmic_duration, :duration, :sounds, :fills_bar, :cue,
      :tie_starts, :tie_stops, :continuation, :link_offset, :link_count, :voice_event, :graces, :staff, :label, :time,
      :ratio
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

      # How far into its chain, from the head's start, this event's first
      # link sounds.
      def link_start
        head.link_starts[first_link]
      end

      def link_starts
        @link_starts ||= rhythmic_duration.values.each_with_object([0]) { |link, starts| starts << starts.last + link.fraction }
      end

      def rest?
        sounds.empty?
      end

      def ties_out?
        ties_every_sound?(tie_starts)
      end

      def ties_in?
        ties_every_sound?(tie_stops)
      end

      def keys
        sounds.map(&:to_s).sort
      end

      # Grace notes before a rest, or before a tie's later link, which is
      # never placed, are dropped.
      def place_on(voice, position)
        self.voice_event = voice.place(position, rhythmic_duration, sounds)
        voice_event.add_grace_notes(*graces.map(&:grace_note)) unless voice_event.rest?
        voice_event
      end

      # A grace note is tied to each pitch it starts a tie on that what
      # follows it shares, the next grace note or the main note, and a tie
      # into the main note takes the place of the stop it carries, so that
      # the main note ends no chain.
      def tie_graces
        return if graces.empty?

        graces.each_cons(2) { |grace, follower| grace.tie_to(follower.sounds) }
        self.tie_stops -= graces.last.tie_to(sounds)
      end

      private

      def ties_every_sound?(pitch_names)
        !rest? && (keys - pitch_names).empty?
      end
    end

    # A grace note waiting for the main note it leads to, and whether it is
    # tied to whatever follows it.
    Grace = Struct.new(:sounds, :rhythmic_value, :slashed, :articulations, :tie_starts, :tied, :label, :event) do
      def grace_note
        HeadMusic::Content::GraceNote.new(sounds: sounds, rhythmic_value: rhythmic_value, slashed: slashed, tied: tied, articulations: articulations)
      end

      # Answers the pitches it ties to.
      def tie_to(follower)
        (tie_starts & follower.map(&:to_s)).tap { |shared| self.tied = shared.any? }
      end
    end

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
      graces = @queued_graces
      @queued_graces = []
      rhythmic_duration = HeadMusic::Rudiment::RhythmicDuration.get(attributes[:rhythmic_duration])
      link_count = rhythmic_duration&.values&.length || 1
      event = Event.new(**attributes, rhythmic_duration: rhythmic_duration, link_count: link_count, label: @label, graces: graces)
      graces.each { |grace| grace.event = event }
      @events << event
      event
    end

    def queue_grace(**attributes)
      Grace.new(**attributes, tied: false, label: @label).tap { |grace| @queued_graces << grace }
    end

    # Answers the grace notes still queued at the end of the part, which
    # lead to nothing and are dropped.
    def tie_graces
      @events.each(&:tie_graces)
      @queued_graces
    end
  end
end
