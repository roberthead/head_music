module HeadMusic::MIDI
  # The wire channel and key a sound of a part strikes. Unpitched sounds go
  # to the percussion channel, even in a pitched part's track.
  class SoundKeys
    attr_reader :part, :channel, :transposed

    # The sounding key, or the written pitch plus the sounding transposition
    # of the instrument in force at the bar when the flow is transposed, as
    # Layout::Realization reads a part's bar.
    def self.key_for(pitch, part, bar_number, transposed:)
      transposition = transposed ? part.instrument_at(bar_number)&.sounding_transposition.to_i : 0
      pitch.midi_note_number + transposition
    end

    def self.percussion_key_for(sound)
      sound.instrument&.gm_percussion_key || DEFAULT_PERCUSSION_KEY
    end

    # +channel+ is the part's pitched channel, nil when it holds no pitch.
    def initialize(part, channel:, transposed:)
      @part = part
      @channel = channel
      @transposed = transposed
    end

    def for(sound, bar_number)
      return [ChannelAllocator::PERCUSSION_CHANNEL, self.class.percussion_key_for(sound)] unless sound.pitched?

      [channel, self.class.key_for(sound, part, bar_number, transposed: transposed)]
    end
  end
end
