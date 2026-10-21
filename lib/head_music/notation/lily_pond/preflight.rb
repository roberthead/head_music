# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Rejects flows that cannot be expressed in the supported LilyPond
  # subset.
  #
  # Whole-flow problems (no voices, positional gaps, underfilled
  # final bars, unpitched sounds) raise RenderError here, before the Writer
  # assembles any output — so a successful check! is the Writer's guarantee
  # that assembly cannot fail on these grounds.
  class Preflight
    include HeadMusic::Notation::PreflightChecks
    include HeadMusic::Notation::VoiceEventValidation

    def self.check!(flow)
      new(flow).check!
    end

    def initialize(flow)
      @flow = flow
    end

    def check!
      ensure_voices
      ensure_contiguous_voices(flow)
      ensure_markings_within_music(flow)
      ensure_timed_marks_within_music(flow)
      ensure_no_marks_inside_rounded_notes(flow)
      ensure_filled_final_bars
      ensure_pitched_voice_events(flow)
      ensure_tempo_marks_writable
    end

    private

    attr_reader :flow

    def ensure_tempo_marks_writable
      marks = HeadMusic::Notation::TempoMarks.new(flow)
      tempo = [marks.opening, *marks.filter_map(&:tempo)].find { |candidate| TempoWriter.problem(candidate) }
      raise RenderError, "cannot write #{TempoWriter.problem(tempo)} in LilyPond output" if tempo

      ramp = marks.unreadable_ramps.first
      raise RenderError, "cannot write the tempo ramp from #{ramp.from} to #{ramp.to} in LilyPond output so that it reads back" if ramp
    end

    def ensure_voices
      return unless flow.voices.empty?

      raise RenderError, "cannot render a flow with no voices as LilyPond"
    end

    # A short final bar, such as one that balances a pickup, is written
    # without a bar check after it, which is only true when every voice ends
    # there. A voice that ends short of the others leaves a gap instead, which
    # would render short of its bar check.
    def ensure_filled_final_bars
      endings = flow.voices.filter_map { |voice| voice.last_voice_event&.next_position }
      return if endings.uniq.length <= 1

      finish = endings.find { |ending| !HeadMusic::Notation::BarSplitter.offset_in_bar(ending).zero? }
      return unless finish

      raise RenderError, "the voice ends mid-bar at #{finish}; " \
        "insert explicit rests to fill the final bar"
    end

    def render_error_class
      RenderError
    end
  end
end
