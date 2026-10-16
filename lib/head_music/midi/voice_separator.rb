module HeadMusic::MIDI
  # Groups one part's quantized notes into chords and deals the chords to
  # voices, each a list of chords in onset order that never overlap.
  class VoiceSeparator
    # +keys+ are sorted and unique.
    Chord = Data.define(:onset, :release, :keys) do
      def duration
        release - onset
      end
    end

    # A voice being filled, with the running key sum that gives its mean
    # without rereading its chords.
    class Lane
      attr_reader :chords, :release

      def initialize
        @chords = []
        @key_sum = 0
        @key_count = 0
      end

      def free_at?(onset)
        release <= onset
      end

      def mean_key
        Rational(@key_sum, @key_count)
      end

      def add(chord, keys)
        @chords << chord
        @release = chord.release
        @key_sum += keys.sum
        @key_count += keys.length
      end
    end
    private_constant :Lane

    def initialize(notes, percussion: false)
      @notes = notes
      @percussion = percussion
    end

    # Voices in voice order, each a list of Chords.
    def voices
      @voices ||= begin
        lanes = []
        chords.each do |chord|
          keys = chord.keys
          mean = Rational(keys.sum, keys.length)
          lane = nearest_free(lanes, chord.onset, mean) || open_lane(lanes)
          lane.add(chord, keys)
        end
        lanes.map { |lane| lane.chords.freeze }.freeze
      end
    end

    private

    def nearest_free(lanes, onset, mean)
      nearest = nil
      nearest_distance = nil
      lanes.each do |lane|
        next unless lane.free_at?(onset)

        distance = (lane.mean_key - mean).abs
        next if nearest_distance && distance >= nearest_distance

        nearest = lane
        nearest_distance = distance
      end
      nearest
    end

    def open_lane(lanes)
      Budget.check_voices!(@notes.first.part_key, lanes.length + 1)
      lanes << Lane.new
      lanes.last
    end

    def chords
      groups.map do |notes|
        Chord.new(
          onset: notes.first.onset,
          release: notes.map(&:release).max,
          keys: notes.map(&:key).uniq.sort.freeze
        )
      end.sort_by { |chord| [chord.onset, -chord.keys.last, chord.release] }
    end

    def groups
      if @percussion
        @notes.group_by(&:onset).values
      else
        @notes.group_by { |note| [note.onset, note.release] }.values
      end
    end
  end
end
