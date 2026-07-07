# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Chooses a clef for a voice based on the midpoint of its pitch range.
  class ClefSelector
    MIDDLE_C_MIDI_NOTE_NUMBER = 60

    # Returns the treble clef for a voice with no notes (rest-only or empty),
    # and otherwise the clef whose side of middle C matches the midpoint of
    # the voice's lowest and highest pitches. A midpoint exactly on middle C
    # is treated as treble.
    def self.for(voice)
      return HeadMusic::Rudiment::Clef.get(:treble_clef) unless voice.lowest_pitch

      if midpoint(voice) < MIDDLE_C_MIDI_NOTE_NUMBER
        HeadMusic::Rudiment::Clef.get(:bass_clef)
      else
        HeadMusic::Rudiment::Clef.get(:treble_clef)
      end
    end

    def self.midpoint(voice)
      (voice.lowest_pitch.midi_note_number + voice.highest_pitch.midi_note_number) / 2.0
    end
    private_class_method :midpoint
  end
end
