module HeadMusic::MIDI
  # Spells every pitched chord once, over the whole file, with each note
  # labeled by its part and voice so that melodic direction applies.
  #
  # With key: nil the file's signatures spell the notes, or the key finder's
  # regions where the file has none. The flow's signatures are the file's,
  # unless the speller inferred the key or the file has none.
  class Spelling
    # +parts+ are [PartSource::Part, voices] pairs in part order.
    def initialize(parts, layout, file_keys, key: nil)
      @parts = parts
      @layout = layout
      @file_keys = file_keys
      @key = key
    end

    # Each pitched chord's pitches, by chord.
    def pitches
      @pitches ||= begin
        spelled = speller.pitches
        chords.each_with_object({}.compare_by_identity) { |chord, by_chord| by_chord[chord] = spelled.shift(chord.keys.length) }
      end
    end

    # The KeyRegions the flow's signatures come from, the first opening it.
    def keys
      return @file_keys unless inferred_keys?

      HeadMusic::Analysis::PitchSpeller::Respelling.signature_changes(speller.regions)
    end

    private

    def inferred_keys?
      @key == :infer || @file_keys.empty?
    end

    def speller_key
      return @key unless @key.nil?

      @file_keys.empty? ? :infer : @file_keys
    end

    def speller
      @speller ||= begin
        input = HeadMusic::Analysis::NoteInput.new(unspelled, @layout.bar_starts)
        HeadMusic::Analysis::PitchSpeller.new(input, key: speller_key)
      end
    end

    def chords
      @chords ||= pitched_voices.flat_map { |_label, chords| chords }
    end

    def unspelled
      pitched_voices.flat_map do |label, chords|
        chords.flat_map do |chord|
          chord.keys.map do |number|
            HeadMusic::Analysis::UnspelledNote.new(number: number, onset: chord.onset, duration: chord.duration, voice: label)
          end
        end
      end
    end

    # [[part index, voice index], chords] for each voice of a pitched part.
    def pitched_voices
      @pitched_voices ||= @parts.each_with_index.flat_map do |(part, voices), part_index|
        next [] if part.percussion?

        voices.each_with_index.map { |chords, voice_index| [[part_index, voice_index], chords] }
      end
    end
  end
end
