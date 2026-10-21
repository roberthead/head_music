# frozen_string_literal: true

module HeadMusic
  module Time
    # The TempoPieces of a timeline from its starting point onward, broken at
    # every change of speed and at both ends of every fermata; the last piece
    # has no finish. A ramp starts from the tempo in force there, and ends in
    # its target unless a tempo change at its end says otherwise; a tempo
    # change inside a ramp, or a ramp overlapping another, yields to the ramp
    # already under way.
    class TempoPieces
      # Below this fraction of its starting speed, a ramp is a constant tempo.
      NEGLIGIBLE_RAMP = 1e-12

      attr_reader :pieces

      def initialize(tempo_map:, meter_scale:, start:, tempo_ramps: [], fermatas: [])
        @meter_scale = meter_scale
        @tempo = tempo_map.events.first.tempo
        @segments = []
        moments(tempo_map, tempo_ramps).each { |subticks, order, item| advance(subticks, order, item) }
        @fermata_stretches = fermatas.to_h { |fermata| [subticks_at(fermata.from)...subticks_at(fermata.to), Rational(fermata.stretch)] }
        @pieces = build_pieces(start)
      end

      def piece_at(subticks)
        in_force(pieces, subticks)
      end

      private

      attr_reader :meter_scale, :segments, :fermata_stretches

      def subticks_at(position)
        meter_scale.subticks_at(position)
      end

      # At one position a ramp ends, then a tempo changes, then a ramp starts.
      def moments(tempo_map, tempo_ramps)
        changes = tempo_map.events.map { |event| [subticks_at(event.position), 1, event.tempo] }
        ramps = tempo_ramps.flat_map { |ramp| [[subticks_at(ramp.from), 2, ramp], [subticks_at(ramp.to), 0, ramp]] }
        (changes + ramps).sort_by { |subticks, order, _item| [subticks, order] }
      end

      def advance(subticks, order, item)
        case order
        when 0 then end_ramp(subticks, item)
        when 1 then change_tempo(subticks, item) unless @ramp
        else start_ramp(subticks, item) unless @ramp
        end
      end

      def end_ramp(subticks, ramp)
        return unless ramp.equal?(@ramp)

        @ramp = nil
        change_tempo(subticks, @target)
      end

      def change_tempo(subticks, tempo)
        @tempo = tempo
        add_segment(subticks, 0)
      end

      def start_ramp(subticks, ramp)
        @ramp = ramp
        @target = ramp.to_tempo || ramp.default_target(@tempo)
        add_segment(subticks, ramp_slope(subticks_at(ramp.to) - subticks))
      end

      # Open-ended until build_pieces cuts them at the boundaries.
      def add_segment(subticks, slope)
        segments.pop if segments.last&.start == subticks
        segments << TempoPiece.new(subticks, nil, @tempo, TempoPiece.speed_of(@tempo), slope, 1)
      end

      def ramp_slope(length)
        from = TempoPiece.speed_of(@tempo)
        change = TempoPiece.speed_of(@target) - from
        (change.abs < NEGLIGIBLE_RAMP * from) ? 0 : change / length
      end

      def build_pieces(start)
        fermata_ends = fermata_stretches.keys.flat_map { |range| [range.begin, range.end] }
        boundaries = [start, *segments.map(&:start), *fermata_ends].select { |subticks| subticks >= start }.sort.uniq
        boundaries.zip(boundaries.drop(1), stretches_at(boundaries)).map do |from, finish, stretch|
          segment = in_force(segments, from)
          segment.with(start: from, finish: finish, speed: segment.speed_at(from), stretch: stretch)
        end
      end

      # The last of the ascending pieces to start by this point, else the first.
      def in_force(list, subticks)
        index = list.bsearch_index { |piece| piece.start > subticks }
        list[index ? [index - 1, 0].max : -1]
      end

      # Where fermatas overlap, the one given first holds.
      def stretches_at(boundaries)
        stretches = Array.new(boundaries.size, 1)
        fermata_stretches.reverse_each do |range, stretch|
          stretches.fill(stretch, boundary_index(boundaries, range.begin)...boundary_index(boundaries, range.end))
        end
        stretches
      end

      def boundary_index(boundaries, subticks)
        boundaries.bsearch_index { |boundary| boundary >= subticks } || boundaries.size
      end
    end
  end
end
