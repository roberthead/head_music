module HeadMusic::Notation::MEI
  # Groups a placed voice's tuplets, for VoicePlacer's tuplet_reader:. MEI's
  # <tuplet>, <tupletSpan>, and @tuplet are not read yet, so it groups
  # nothing.
  class TupletReader
    def initialize(voice, track, reading)
      @voice = voice
      @track = track
      @reading = reading
    end

    def group
    end
  end
end
