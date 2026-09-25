# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # Rejects flows that cannot be expressed in the supported kern subset,
  # before the Writer assembles any output.
  #
  # Kern states one instrument and one set of staves per spine for the
  # whole piece here, so a change to either is refused rather than dropped.
  class Preflight
    include HeadMusic::Notation::PreflightChecks
    include HeadMusic::Notation::PlacementValidation

    def self.check!(flow, transposed: false)
      new(flow, transposed).check!
    end

    def initialize(flow, transposed)
      @flow = flow
      @transposed = transposed
    end

    def check!
      ensure_voices
      ensure_contiguous_voices(flow)
      ensure_pitched_placements
      ensure_concert_pitch
      ensure_steady_parts
    end

    private

    attr_reader :flow

    def ensure_voices
      raise RenderError, "cannot render a flow with no voices as kern" if flow.voices.empty?
    end

    def ensure_pitched_placements
      flow.voices.each do |voice|
        voice.placements.each { |placement| ensure_pitched_sounds(placement) }
      end
    end

    # A written-pitch kern spine would need *ITr, which the reader refuses,
    # so a transposing part can only be written at concert pitch.
    def ensure_concert_pitch
      return unless @transposed

      transposing = flow.parts.find { |part| part.instruments.any?(&:transposing?) }
      return unless transposing

      raise RenderError, "kern is written at concert pitch; #{transposing.instrument} transposes"
    end

    def ensure_steady_parts
      flow.parts.each do |part|
        raise RenderError, "kern cannot write an instrument change within a part" if part.instrument_changes.any?
        raise RenderError, "kern cannot write a staff system change within a part" if part.staff_system_changes.any?
      end
    end

    def render_error_class
      RenderError
    end
  end
end
