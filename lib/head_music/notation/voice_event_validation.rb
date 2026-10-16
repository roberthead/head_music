module HeadMusic
  module Notation
    # Voice event checks shared by the notation writers. Both the ABC and
    # MusicXML writers reject percussion (unpitched) sounds identically;
    # each includer supplies its own format-specific RenderError subclass
    # through #render_error_class.
    module VoiceEventValidation
      private

      def ensure_pitched_sounds(voice_event)
        unpitched = voice_event.sounds.find { |sound| !sound.pitched? }
        return unless unpitched

        raise render_error_class, "cannot render unpitched sound \"#{unpitched}\" at #{voice_event.position}: " \
          "percussion rendering is not yet supported"
      end

      def ensure_pitched_voice_events(flow)
        flow.voices.each do |voice|
          voice.voice_events.each { |voice_event| ensure_pitched_sounds(voice_event) }
          voice.note_events.each { |note_event| ensure_pitched_grace_notes(note_event) }
        end
      end

      def ensure_pitched_grace_notes(note_event)
        unpitched = note_event.grace_notes.flat_map(&:sounds).find { |sound| !sound.pitched? }
        return unless unpitched

        raise render_error_class, "cannot render the unpitched grace note \"#{unpitched}\" before #{note_event.position}: " \
          "percussion rendering is not yet supported"
      end
    end
  end
end
