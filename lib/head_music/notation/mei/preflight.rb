module HeadMusic::Notation::MEI
  # Rejects flows that cannot be expressed in the supported MEI subset,
  # before the Writer assembles any output.
  class Preflight
    include HeadMusic::Notation::PreflightChecks
    include HeadMusic::Notation::VoiceEventValidation

    # +texts+ are those the writer is given rather than reads from the flow.
    def self.check!(flow, texts = [])
      new(flow, texts).check!
    end

    def initialize(flow, texts = [])
      @flow = flow
      @texts = texts
    end

    def check!
      ensure_voice_events
      ensure_xml_text(flow_texts + texts)
      ensure_contiguous_voices(flow)
      ensure_markings_within_music(flow)
      ensure_timed_marks_within_music(flow)
      ensure_no_marks_inside_rounded_notes(flow)
      ensure_pitched_voice_events(flow)
      ensure_steady_staff_systems
    end

    private

    attr_reader :flow, :texts

    def ensure_voice_events
      return if flow.voices.any? { |voice| voice.voice_events.any? }

      raise RenderError, "cannot render a flow with no voice events as MEI"
    end

    def flow_texts
      [
        flow.name, flow.composer, flow.work&.title,
        *flow.work&.credits&.map { |credit| credit.person.full_name },
        *flow.parts.flat_map { |part| [part.player&.name, *part.instruments.map(&:name)] },
        *flow.voices.map(&:role),
        *flow.bars(flow.last_sounding_bar_number).map(&:rehearsal_mark),
        *flow.voices.flat_map { |voice| voice.voice_events.flat_map { |event| event.syllables.values.map(&:text) } }
      ]
    end

    # A change would renumber the staves that control events name.
    def ensure_steady_staff_systems
      return unless flow.parts.any? { |part| part.staff_system_changes.any? }

      raise RenderError, "MEI cannot write a staff system change within a part"
    end

    def render_error_class
      RenderError
    end
  end
end
