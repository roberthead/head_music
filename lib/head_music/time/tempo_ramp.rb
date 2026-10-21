# frozen_string_literal: true

module HeadMusic
  module Time
    # A gradual change of tempo from one position to a later one, linear in
    # beats per minute over musical position, toward a target tempo. With no
    # target, the timeline resolves one where it is needed.
    TempoRamp = Data.define(:from, :to, :to_tempo, :text)

    class TempoRamp
      ACCELERATING = /\b(accel|stringendo)/i

      def initialize(from:, to:, to_tempo: nil, text: nil)
        raise ArgumentError, "a tempo ramp ends after it begins, got #{from} to #{to}" unless (from.to_a <=> to.to_a).negative?
        unless to_tempo.nil? || to_tempo.beats_per_minute.positive?
          raise ArgumentError, "a tempo ramp's target tempo must be faster than zero, got #{to_tempo.beats_per_minute}"
        end

        super
      end

      def accelerating?
        text.to_s.match?(ACCELERATING)
      end

      # The target when none is written: three quarters of the starting tempo,
      # or four thirds for an accelerando.
      def default_target(start_tempo)
        factor = accelerating? ? Rational(4, 3) : Rational(3, 4)
        HeadMusic::Rudiment::Tempo.new(start_tempo.beat_value.to_s, start_tempo.beats_per_minute * factor, metronome_mark: false)
      end
    end
  end
end
