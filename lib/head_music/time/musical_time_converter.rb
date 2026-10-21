# frozen_string_literal: true

module HeadMusic
  module Time
    # Converts between clock time (elapsed nanoseconds) and musical position
    # (bars:beats:ticks:subticks) using a tempo map and a meter map, through
    # tempo ramps and fermatas. Both directions pass through subticks measured
    # along a MeterScale, so a tempo segment that crosses a meter change counts
    # each bar in its own meter.
    class MusicalTimeConverter
      # Below this fraction of its starting speed, a ramp is a constant tempo.
      NEGLIGIBLE_RAMP = 1e-12

      def initialize(tempo_map:, meter_map:, starting_musical_position:, tempo_ramps: [], fermatas: [])
        @tempo_map = tempo_map
        @meter_scale = MeterScale.new(meter_map)
        @starting_musical_position = starting_musical_position
        @tempo_ramps = tempo_ramps
        @fermatas = fermatas
      end

      # @param clock_position [ClockPosition] the clock time to convert
      # @return [MusicalPosition] the corresponding musical position
      def clock_to_musical(clock_position)
        remaining = Rational(clock_position.nanoseconds)
        pieces.each do |piece|
          if piece.finish.nil? || piece.duration >= remaining
            offset = piece.subticks_after(remaining).round
            offset = [offset, piece.finish - piece.start].min if piece.finish
            return meter_scale.position_at(piece.start + offset)
          end
          remaining -= piece.duration
        end
      end

      # @param musical_position [MusicalPosition] the musical position to convert
      # @return [ClockPosition] the corresponding clock time
      def musical_to_clock(musical_position)
        target = subticks_at(musical_position)
        exact = Rational(0)
        inexact = 0
        pieces.each do |piece|
          break if piece.start >= target

          duration = piece.duration(piece.finish.nil? ? target : [piece.finish, target].min)
          if duration.is_a?(Float)
            inexact += duration
          else
            exact += duration
          end
        end
        ClockPosition.new((exact + inexact).round)
      end

      # @return [HeadMusic::Rudiment::Tempo] the tempo sounding at a position,
      #   interpolated inside a ramp
      def tempo_at(musical_position)
        subticks = [subticks_at(musical_position), pieces.first.start].max
        pieces.find { |piece| piece.finish.nil? || subticks < piece.finish }.tempo_at(subticks)
      end

      private

      attr_reader :tempo_map, :meter_scale, :starting_musical_position, :tempo_ramps, :fermatas

      def subticks_at(position)
        position = MusicalPosition.new(*position.to_a) unless position.is_a?(MusicalPosition)
        meter_scale.subticks_at(position)
      end

      # From the starting position onward, broken at every change of speed
      # and at both ends of every fermata; the last piece has no finish.
      def pieces
        @pieces ||= begin
          start = subticks_at(starting_musical_position)
          boundaries = [start, *speed_segments.map(&:first), *fermata_ranges.flat_map { |range| [range.begin, range.end] }]
            .select { |subticks| subticks >= start }.sort.uniq
          boundaries.each_with_index.map do |from, index|
            piece_from(from, boundaries[index + 1])
          end
        end
      end

      def piece_from(from, finish)
        position, tempo, speed, slope = speed_segments.reverse_each.find { |segment| segment.first <= from } || speed_segments.first
        fermata = fermata_ranges.find { |range| range.cover?(from) }
        TempoPiece.new(from, finish, tempo, speed + slope * (from - position), slope, fermata ? Rational(fermata_stretches[fermata]) : 1)
      end

      def fermata_ranges
        @fermata_ranges ||= fermatas.map { |fermata| subticks_at(fermata.from)...subticks_at(fermata.to) }
      end

      def fermata_stretches
        @fermata_stretches ||= fermata_ranges.zip(fermatas.map(&:stretch)).to_h
      end

      # [subticks, tempo, speed, slope] at each change of speed, each in force
      # until the next. A ramp starts from the tempo in force there, and ends
      # in its target unless a tempo change at its end says otherwise; a tempo
      # change inside a ramp, or a ramp overlapping another, yields to the
      # ramp already under way.
      def speed_segments
        @speed_segments ||= begin
          segments = []
          tempo = tempo_map.events.first.tempo
          ramp = target = nil
          moments.each do |subticks, order, item|
            case order
            when 0
              next unless item.equal?(ramp)

              ramp = nil
              tempo = target
              add_segment(segments, subticks, tempo, 0)
            when 1
              next if ramp

              tempo = item
              add_segment(segments, subticks, tempo, 0)
            else
              next if ramp

              ramp = item
              target = ramp.to_tempo || ramp.default_target(tempo)
              add_segment(segments, subticks, tempo, ramp_slope(tempo, target, subticks_at(ramp.to) - subticks))
            end
          end
          segments
        end
      end

      # At one position a ramp ends, then a tempo changes, then a ramp starts.
      def moments
        changes = tempo_map.events.map { |event| [subticks_at(event.position), 1, event.tempo] }
        ramps = tempo_ramps.flat_map { |ramp| [[subticks_at(ramp.from), 2, ramp], [subticks_at(ramp.to), 0, ramp]] }
        (changes + ramps).sort_by { |subticks, order, _item| [subticks, order] }
      end

      def add_segment(segments, subticks, tempo, slope)
        segment = [subticks, tempo, TempoPiece.speed_of(tempo), slope]
        if segments.last&.first == subticks
          segments[-1] = segment
        else
          segments << segment
        end
      end

      def ramp_slope(tempo, target, length)
        from = TempoPiece.speed_of(tempo)
        change = TempoPiece.speed_of(target) - from
        (change.abs < NEGLIGIBLE_RAMP * from) ? 0 : change / length
      end
    end
  end
end
