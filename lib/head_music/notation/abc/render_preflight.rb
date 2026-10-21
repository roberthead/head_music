# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Rejects flows that cannot be expressed in the supported ABC subset,
  # before the Writer assembles any output.
  #
  # A tune is written as one voice with one M: and one K: field, so a second
  # voice or a mid-piece change is refused rather than dropped.
  class RenderPreflight
    include HeadMusic::Notation::PreflightChecks

    def self.check!(flow, transposed: false)
      new(flow, transposed).check!
    end

    def initialize(flow, transposed)
      @flow = flow
      @transposed = transposed
    end

    def check!
      ensure_single_voice
      ensure_tuplets_within_bars(flow)
      ensure_no_mid_piece_changes
      ensure_no_instrument_change
      ensure_contiguous_voices(flow)
      ensure_markings_within_music(flow)
      ensure_timed_marks_within_music(flow)
      ensure_no_marks_inside_rounded_notes(flow)
      ensure_dynamics_fit_one_voice
      ensure_tempo_marks_writable
    end

    private

    attr_reader :flow

    def ensure_single_voice
      return if flow.voices.length <= 1

      raise RenderError, "multi-voice ABC output is not supported"
    end

    def ensure_no_mid_piece_changes
      refuse_change("meter", flow.meter_changes.keys)
      refuse_change("key signature", flow.key_signature_changes.keys)
    end

    # A part that picks up an instrument reading in another key needs a
    # second K: field -- the same limit as a mid-piece key change.
    def ensure_no_instrument_change
      return unless @transposed

      refuse_change("instrument", flow.parts.flat_map { |part| part.instrument_changes.keys })
    end

    def refuse_change(subject, bar_numbers)
      bar_number = bar_numbers.min
      return unless bar_number

      raise RenderError, "cannot render the #{subject} change at bar #{bar_number} in ABC output"
    end

    # The parts' dynamics are written in the one voice.
    def ensure_dynamics_fit_one_voice
      holders = flow.parts + flow.voices
      ensure_one_level_per_position(holders, line: "an ABC voice")
      ensure_one_hairpin_at_a_time(holders.flat_map(&:spans), line: "an ABC voice")
    end

    def ensure_tempo_marks_writable
      marks = HeadMusic::Notation::TempoMarks.new(flow)
      tempo = [marks.opening, *marks.filter_map(&:tempo)].find { |candidate| TempoField.problem(candidate) }
      raise RenderError, "cannot write #{TempoField.problem(tempo)} in ABC output" if tempo

      mark = marks.find { |candidate| candidate.text&.include?('"') }
      raise RenderError, "cannot write the text #{mark.text.inspect}, which holds a double quote, in ABC output" if mark

      ramp = marks.unreadable_ramps.first
      raise RenderError, "cannot write the tempo ramp from #{ramp.from} to #{ramp.to} in ABC output so that it reads back" if ramp
    end

    def render_error_class
      RenderError
    end
  end
end
