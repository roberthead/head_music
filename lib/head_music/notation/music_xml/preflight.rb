# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Rejects flows that cannot be expressed in the supported MusicXML
  # subset.
  #
  # Whole-flow problems (no voices, positional gaps, characters XML
  # forbids) raise RenderError here, before the
  # Writer assembles any output — so a successful check! is the Writer's
  # guarantee that assembly cannot fail on these grounds.
  class Preflight
    include HeadMusic::Notation::PreflightChecks

    # +texts+ are those the writer is given rather than reads from the flow.
    def self.check!(flow, texts = [])
      new(flow, texts).check!
    end

    def initialize(flow, texts = [])
      @flow = flow
      @texts = texts
    end

    def check!
      ensure_voices
      ensure_xml_text(flow_texts(flow) + part_texts + texts)
      ensure_contiguous_voices(flow)
      ensure_markings_within_music(flow)
      ensure_timed_marks_within_music(flow)
      ensure_no_marks_inside_rounded_notes(flow)
    end

    private

    attr_reader :flow, :texts

    def ensure_voices
      return unless flow.voices.empty?

      raise RenderError, "cannot render a flow with no voices as MusicXML"
    end

    def part_texts
      flow.parts.flat_map { |part| [part.player&.name, part.instrument&.name] }
    end

    def render_error_class
      RenderError
    end
  end
end
