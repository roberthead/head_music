module HeadMusic
  module Notation
    # Placement checks shared by the notation writers. Both the ABC and
    # MusicXML writers reject percussion (unpitched) sounds identically;
    # each includer supplies its own format-specific RenderError subclass
    # through #render_error_class.
    module PlacementValidation
      private

      def ensure_pitched_sounds(placement)
        unpitched = placement.sounds.find { |sound| !sound.pitched? }
        return unless unpitched

        raise render_error_class, "cannot render unpitched sound \"#{unpitched}\" at #{placement.position}: " \
          "percussion rendering is not yet supported"
      end
    end
  end
end
