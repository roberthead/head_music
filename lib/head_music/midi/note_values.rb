module HeadMusic::MIDI
  # Writes spans of Rational whole notes as rhythmic values in the layout's
  # bars.
  class NoteValues
    attr_reader :layout

    def initialize(layout)
      @layout = layout
    end

    # One rhythmic value, a tied chain where no single value fits, for a note
    # from its onset to its release.
    def value(onset, release)
      plain(release - onset)
    end

    # The rests filling a gap, each with the time it starts at.
    def rests(from, to)
      rests = []
      while from < to
        segment_end = [layout.bar_at(from).end_time, to].min
        segment_end = to if segment_end <= from
        rests << [from, plain(segment_end - from)]
        from = segment_end
      end
      rests
    end

    private

    def plain(duration)
      HeadMusic::Notation::DottedDuration.rest_value(duration) ||
        raise(UnsupportedFeatureError, "no rhythmic value spans #{duration} of a whole note")
    end
  end
end
