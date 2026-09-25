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
    include HeadMusic::Notation::PlacementValidation

    def self.check!(flow)
      new(flow).check!
    end

    def initialize(flow)
      @flow = flow
    end

    def check!
      ensure_voices
      ensure_contiguous_voices(flow)
      ensure_filled_final_bars
      ensure_pitched_placements
    end

    private

    attr_reader :flow

    def ensure_voices
      return unless flow.voices.empty?

      raise RenderError, "cannot render a flow with no voices as LilyPond"
    end

    def ensure_pitched_placements
      flow.voices.each do |voice|
        voice.placements.each { |placement| ensure_pitched_sounds(placement) }
      end
    end

    # A short final bar, such as one that balances a pickup, is written
    # without a bar check after it, which is only true when every voice ends
    # there. A voice that ends short of the others leaves a gap instead, which
    # would render short of its bar check.
    def ensure_filled_final_bars
      endings = flow.voices.filter_map { |voice| voice.last_placement&.next_position }
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
