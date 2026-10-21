# frozen_string_literal: true

module HeadMusic
  module Time
    # Converts between clock time (elapsed nanoseconds) and musical position
    # (bars:beats:ticks:subticks) using a tempo map and a meter map, through
    # tempo ramps and fermatas. Both directions pass through subticks measured
    # along a MeterScale, so a tempo segment that crosses a meter change counts
    # each bar in its own meter.
    class MusicalTimeConverter
      def initialize(tempo_map:, meter_map:, starting_musical_position:, tempo_ramps: [], fermatas: [])
        @meter_scale = MeterScale.new(meter_map)
        @tempo_pieces = TempoPieces.new(
          tempo_map: tempo_map, meter_scale: meter_scale, start: meter_scale.subticks_at(starting_musical_position),
          tempo_ramps: tempo_ramps, fermatas: fermatas
        )
      end

      # @param clock_position [ClockPosition] the clock time to convert
      # @return [MusicalPosition] the corresponding musical position
      def clock_to_musical(clock_position)
        remaining = Rational(clock_position.nanoseconds)
        pieces.each do |piece|
          return meter_scale.position_at(piece.subticks_reached(remaining)) if piece.lasts?(remaining)

          remaining -= piece.duration
        end
      end

      # @param musical_position [MusicalPosition] the musical position to convert
      # @return [ClockPosition] the corresponding clock time
      def musical_to_clock(musical_position)
        target = meter_scale.subticks_at(musical_position)
        durations = pieces.take_while { |piece| piece.start < target }.map { |piece| piece.duration(target) }
        ClockPosition.new((durations.grep_v(Float).sum(Rational(0)) + durations.grep(Float).inject(0, :+)).round)
      end

      # @return [HeadMusic::Rudiment::Tempo] the tempo sounding at a position,
      #   interpolated inside a ramp
      def tempo_at(musical_position)
        subticks = [meter_scale.subticks_at(musical_position), pieces.first.start].max
        tempo_pieces.piece_at(subticks).tempo_at(subticks)
      end

      private

      attr_reader :meter_scale, :tempo_pieces

      delegate :pieces, to: :tempo_pieces
    end
  end
end
