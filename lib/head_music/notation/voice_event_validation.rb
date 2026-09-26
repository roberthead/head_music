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
    end
  end
end
