module HeadMusic::MIDI
  # The pieces a note event sounds as, in exact whole notes from its onset.
  # Each piece carries the sounds it strikes and their velocity, and an +id+
  # unique within the event, which joins the parts of one piece that the
  # barlines cut.
  #
  # For now a note event sounds whole, as one piece.
  class NoteTiming
    Piece = Data.define(:sounds, :from, :to, :velocity, :id)

    attr_reader :voice_event, :velocity_resolver

    def initialize(voice_event, velocity_resolver)
      @voice_event = voice_event
      @velocity_resolver = velocity_resolver
    end

    def pieces
      [Piece.new(voice_event.sounds, 0, voice_event.rhythmic_value.fraction, velocity_resolver.velocity(voice_event), 0)]
    end
  end
end
