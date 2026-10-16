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

    def initialize(notes, percussion: false)
      @notes = notes
      @percussion = percussion
    end

    # Voices in voice order, each a list of Chords.
    def voices
      @voices ||= begin
        voices = []
        chords.each do |chord|
          voice = voices.find { |candidate| candidate.last.release <= chord.onset }
          voice ? voice << chord : open_voice(voices) << chord
        end
        voices.map(&:freeze).freeze
      end
    end

    private

    def open_voice(voices)
      Budget.check_voices!(@notes.first.part_key, voices.length + 1)
      voices << []
      voices.last
    end

    def chords
      @notes.group_by { |note| [note.onset, note.release] }.map do |(onset, release), notes|
        Chord.new(onset: onset, release: release, keys: notes.map(&:key).uniq.sort.freeze)
      end.sort_by { |chord| [chord.onset, -chord.keys.last] }
    end
  end
end
