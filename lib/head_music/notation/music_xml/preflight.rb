# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Rejects flows that cannot be expressed in the supported MusicXML
  # subset.
  #
  # Whole-flow problems (no voices, positional gaps, barline-crossing
  # notes, forbidden control characters) raise RenderError here, before the
  # Writer assembles any output — so a successful check! is the Writer's
  # guarantee that assembly cannot fail on these grounds.
  class Preflight
    include HeadMusic::Notation::PreflightChecks

    # XML 1.0 forbids the C0 control characters other than tab, newline, and
    # carriage return, even as character references.
    FORBIDDEN_TEXT_CHARACTERS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F]/

    def self.check!(flow)
      new(flow).check!
    end

    def initialize(flow)
      @flow = flow
    end

    def check!
      ensure_voices
      ensure_renderable_text
      ensure_contiguous_voices(flow)
      ensure_notes_within_barlines(flow)
    end

    private

    attr_reader :flow

    def ensure_voices
      return unless flow.voices.empty?

      raise RenderError, "cannot render a flow with no voices as MusicXML"
    end

    def ensure_renderable_text
      texts = [flow.name, flow.composer] + flow.voices.map(&:role)
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
