# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # Rejects flows that cannot be expressed in the supported kern subset,
  # before the Writer assembles any output.
  #
  # Kern states one instrument and one set of staves per spine for the
  # whole piece here, so a change to either is refused rather than dropped.
  class Preflight
    include HeadMusic::Notation::PreflightChecks
    include HeadMusic::Notation::VoiceEventValidation

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
      ensure_markings_within_music(flow)
      ensure_timed_marks_within_music(flow)
      ensure_no_marks_inside_rounded_notes(flow)
      ensure_pitched_voice_events(flow)
      ensure_concert_pitch
      ensure_steady_parts
      ensure_dynamics_have_voices
      ensure_one_level_per_dynamics_spine
      ensure_one_hairpin_per_dynamics_spine
    end

    private

    attr_reader :flow

    def ensure_voices
      raise RenderError, "cannot render a flow with no voices as kern" if flow.voices.empty?
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

    # A **dynam spine belongs to the **kern spine on its left, so a part with
    # no voices has none to hold its dynamics.
    def ensure_dynamics_have_voices
      voiceless = flow.parts.find { |part| part.voices.empty? && (part.dynamic_events.any? || part.spans.any?(&:hairpin?)) }
      raise RenderError, "kern cannot write the dynamics of a part with no voices" if voiceless
    end

    def ensure_one_level_per_dynamics_spine
      flow.parts.each { |part| ensure_one_level_per_position([part, *part.voices], line: "a part's **dynam spine") }
    end

    # Pieces, since a level inside a hairpin cuts it, and pieces that touch
    # can both be written, as `]p<`.
    def ensure_one_hairpin_per_dynamics_spine
      flow.parts.each do |part|
        ensure_one_hairpin_at_a_time(DynamicFields.new(part).hairpins, line: "a part's **dynam spine")
      end
    end

    def render_error_class
      RenderError
    end
  end
end
