# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Rejects compositions that cannot be expressed in the supported LilyPond
  # subset, and normalizes each bar's meter and key-signature markers in
  # place so later positional arithmetic and assembly can rely on coerced
  # values.
  #
  # Whole-composition problems (no voices, positional gaps, barline-crossing
  # notes, unpitched sounds) raise RenderError here, before the Writer
  # assembles any output — so a successful check! is the Writer's guarantee
  # that assembly cannot fail on these grounds.
  class Preflight
    include HeadMusic::Notation::PreflightChecks
    include HeadMusic::Notation::PlacementValidation

    def self.check!(composition)
      new(composition).check!
    end

    def initialize(composition)
      @composition = composition
    end

    def check!
      ensure_voices
      normalize_bar_markers(composition)
      ensure_contiguous_voices(composition)
      ensure_notes_within_barlines(composition)
      ensure_pitched_placements
    end

    private

    attr_reader :composition

    def ensure_voices
      return unless composition.voices.empty?

      raise RenderError, "cannot render a composition with no voices as LilyPond"
    end

    def ensure_pitched_placements
      composition.voices.each do |voice|
        voice.placements.each { |placement| ensure_pitched_sounds(placement) }
      end
    end

    def render_error_class
      RenderError
    end
  end
end
