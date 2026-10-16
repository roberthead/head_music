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

    # A layer as read in a measure, waiting for its voice: the staff it
    # sits on, and each entry with the sounds of its notes and its Pending
    # records.
    Layer = Struct.new(:measure_index, :content, :staff, :entries)

    attr_reader :definition, :measures, :transposition, :instrument_changes, :layers, :roles

    # By track, the first and last events of each tuplet group.
    attr_writer :tuplet_groups

    # Whether the voices are keyed by staff and layer, not layer alone.
    attr_accessor :by_staff

    def tuplet_groups
      @tuplet_groups || {}
    end

    def initialize(definition)
      @definition = definition
      @measures = []
      @tracks = {}
      @instrument_changes = {}
      @layers = []
      @roles = {}
      @transposition = HeadMusic::Notation::ConcertTransposition.new(errors: HeadMusic::Notation::MEI)
    end

    def errors
      HeadMusic::Notation::MEI
    end

    def where(measure_index)
      {measure: measure_index && measures[measure_index]&.number, staff: definition.staff_numbers.first}
    end

    # The track of a voice key, made on first use.
    def track(key, label = key.to_s)
      @tracks[key] ||= HeadMusic::Notation::VoiceTrack.new(label)
    end

    # The track of a layer on a staff, by whichever key the part's voices
    # take, or nil.
    def layer_track(staff_number, layer_number)
      by_staff ? @tracks[[definition.staff_index(staff_number), layer_number]] : @tracks[layer_number]
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
