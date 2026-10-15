module HeadMusic::MIDI
  # The wire channel each pitched part plays on, in part order around the
  # percussion channel. A part is pitched by the sounds it holds, not by its
  # instrument, since a timpani part is pitched though its notation is not.
  # Parts that play one instrument throughout share its channel.
  class ChannelAllocator
    PERCUSSION_CHANNEL = 9
    PITCHED_CHANNELS = ((0..15).to_a - [PERCUSSION_CHANNEL]).freeze

    attr_reader :flow

    def initialize(flow)
      @flow = flow
      @channels = allocate
    end

    # Nil for a part that holds no pitch.
    def channel_for(part)
      @channels[part]
    end

    def self.pitched?(part)
      part.voices.any? do |voice|
        voice.note_events.any? do |voice_event|
          voice_event.pitched? || voice_event.grace_notes.any? { |grace_note| grace_note.pitches.any? }
        end
      end
    end

    private

    def allocate
      pitched = flow.parts.select { |part| self.class.pitched?(part) }
      keys = pitched.map { |part| sharing_key(part) }.uniq
      if keys.length > PITCHED_CHANNELS.length
        raise RenderError, "the flow needs #{keys.length} pitched channels, and MIDI has #{PITCHED_CHANNELS.length} beside percussion"
      end

      pitched.to_h { |part| [part, PITCHED_CHANNELS.fetch(keys.index(sharing_key(part)))] }.compare_by_identity
    end

    def sharing_key(part)
      instrument = part.instrument
      (instrument && part.instruments == [instrument]) ? instrument.name_key : part
    end
  end
end
