module HeadMusic::MIDI
  # The velocity each note event of a voice attacks with, 1..127.
  #
  # For now every note sounds at the default.
  class VelocityResolver
    DEFAULT_VELOCITY = 80

    attr_reader :voice

    def initialize(voice)
      @voice = voice
    end

    def velocity(_voice_event)
      DEFAULT_VELOCITY
    end

    def grace_velocity(_voice_event, _grace_note)
      DEFAULT_VELOCITY
    end
  end
end
