# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Rejects compositions that cannot be expressed in the supported MusicXML
  # subset.
  #
  # Whole-composition problems (no voices, positional gaps, barline-crossing
  # notes, forbidden control characters) raise RenderError here, before the
  # Writer assembles any output — so a successful check! is the Writer's
  # guarantee that assembly cannot fail on these grounds.
  class Preflight
    include HeadMusic::Notation::PreflightChecks

    # XML 1.0 forbids the C0 control characters other than tab, newline, and
    # carriage return, even as character references.
    FORBIDDEN_TEXT_CHARACTERS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F]/

    def self.check!(composition)
      new(composition).check!
    end

    def initialize(composition)
      @composition = composition
    end

    def check!
      ensure_voices
      ensure_renderable_text
      ensure_contiguous_voices(composition)
      ensure_notes_within_barlines(composition)
    end

    private

    attr_reader :composition

    def ensure_voices
      return unless composition.voices.empty?

      raise RenderError, "cannot render a composition with no voices as MusicXML"
    end

    def ensure_renderable_text
      texts = [composition.name, composition.composer] + composition.voices.map(&:role)
      texts.compact.each do |text|
        next unless text.to_s.match?(FORBIDDEN_TEXT_CHARACTERS)

        raise RenderError, "cannot render control characters in #{text.to_s.inspect} as XML text"
      end
    end

    def render_error_class
      RenderError
    end
  end
end
