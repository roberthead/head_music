module HeadMusic::MIDI
  # One part in the shape the shared notation core takes: the layout's bars
  # as measures, the same for every part, and a VoiceTrack for each voice,
  # its notes and the rests between them written by NoteValues. A whole bar
  # of rest fills its bar, so that VoicePlacer fills it, or leaves it out at
  # the edges of a voice it trims. Times are exact, so the tolerance is 0.
  class PartReading
    Measure = Data.define(:index, :implicit, :extent, :meter, :tolerance)

    # MIDI writes no tuplet brackets to group.
    class NoTuplets
      def initialize(_voice, _track, _reading)
      end

      def group
      end
    end

    def self.measures(layout)
      layout.bars.each_with_index.map do |bar, index|
        Measure.new(index: index, implicit: bar.number.zero?, extent: bar.length, meter: bar.meter, tolerance: 0)
      end.freeze
    end

    attr_reader :measures, :tracks

    # +voices+ are lists of [onset, release, sounds], in onset order.
    def initialize(measures, layout: nil, values: nil, voices: [], label: nil)
      @measures = measures
      @layout = layout
      @values = values
      @tracks = voices.each_with_index.map { |notes, index| track("#{label}, voice #{index + 1}", notes) }
    end

    def errors
      HeadMusic::MIDI
    end

    def where(_measure_index)
      {}
    end

    private

    def track(label, notes)
      track = HeadMusic::Notation::VoiceTrack.new(label)
      time = @layout.bars.first.start
      notes.each do |onset, release, sounds|
        add_rests(track, time, onset)
        add(track, onset, @values.rhythmic_duration(onset, release), sounds)
        time = release
      end
      add_rests(track, time, @layout.end_time)
      track
    end

    def add_rests(track, from, to)
      @values.rests(from, to).each do |time, value|
        bar = @layout.bar_at(time)
        add(track, time, value, [], fills_bar: time == bar.start && value.fraction == bar.length)
      end
    end

    def add(track, time, rhythmic_duration, sounds, fills_bar: false)
      bar = @layout.bar_at(time)
      track.add(
        measure_index: bar.number - @layout.first_number, cursor: time - bar.start, tolerance: 0,
        rhythmic_duration: rhythmic_duration, sounds: sounds, fills_bar: fills_bar, staff: 1, tie_starts: [], tie_stops: []
      )
    end
  end
end
