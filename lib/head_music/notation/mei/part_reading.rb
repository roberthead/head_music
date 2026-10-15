module HeadMusic::Notation::MEI
  # One part as phase one reads it, in the shape the shared core takes: its
  # measures, one per bar of the score, and a VoiceTrack for each voice,
  # each answering where an index is for messages. Durations are read
  # exactly, so the tolerance only lets a tie's next link follow its last
  # where the times are equal.
  class PartReading
    TOLERANCE = Rational(1, 1_000_000)

    # What the shared BarMap reads of a measure, and the clefs it opens with
    # by staff in the part.
    Measure = Struct.new(:index, :number, :implicit, :extent, :meter, :tolerance, :clefs)

    attr_reader :definition, :measures, :transposition, :instrument_changes

    def initialize(definition)
      @definition = definition
      @measures = []
      @tracks = {}
      @instrument_changes = {}
      @transposition = HeadMusic::Notation::ConcertTransposition.new(errors: HeadMusic::Notation::MEI)
    end

    def errors
      HeadMusic::Notation::MEI
    end

    def where(measure_index)
      {measure: measure_index && measures[measure_index]&.number, staff: definition.staff_numbers.first}
    end

    # The track of a voice key, made on first use.
    def track(key)
      @tracks[key] ||= HeadMusic::Notation::VoiceTrack.new(key.to_s)
    end

    # The tracks in voice-key order.
    def tracks
      @tracks.sort_by { |key, _| Array(key) }.map(&:last)
    end

    def keyed_tracks
      @tracks.sort_by { |key, _| Array(key) }
    end
  end
end
