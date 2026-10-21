# frozen_string_literal: true

module HeadMusic
  module Time
    # A stretch of the subtick axis over which speed, in subticks per
    # nanosecond, is constant or changes linearly, under one fermata stretch.
    # A constant piece's clock time is an exact Rational; a ramp's is a Float,
    # in the closed forms of integrating 1 / (speed + slope * x).
    TempoPiece = Data.define(:start, :finish, :tempo, :speed, :slope, :stretch)

    class TempoPiece
      def self.speed_of(tempo)
        tempo.beats_per_minute.to_r * tempo.ticks_per_beat.to_r * HeadMusic::Time::SUBTICKS_PER_TICK /
          HeadMusic::Rudiment::Tempo::NANOSECONDS_PER_MINUTE
      end

      def ramp?
        !slope.zero?
      end

      def lasts?(nanoseconds)
        finish.nil? || duration >= nanoseconds
      end

      # Where the piece reaches a clock time from its start, stopping at the
      # finish.
      def subticks_reached(nanoseconds)
        [start + subticks_after(nanoseconds).round, finish].compact.min
      end

      def speed_at(subticks)
        speed + slope * (subticks - start)
      end

      # Clock time from the start to a point, stopping at the finish.
      # atanh(u / (2v + u)) is half of ln((v + u) / v) without the
      # cancellation of a logarithm near 1.
      def duration(upto = finish)
        length = [upto, finish].compact.min - start
        time = if ramp?
          change = slope * length
          (2 / slope) * Math.atanh(change / (2 * speed + change))
        else
          length / speed
        end
        time * stretch
      end

      def subticks_after(nanoseconds)
        time = nanoseconds / stretch
        return time * speed unless ramp?

        half = Math.tanh(slope * time / 2)
        (speed / slope) * (2 * half / (1 - half))
      end

      # The tempo sounding here, in the beat value of the tempo the piece
      # starts from.
      def tempo_at(subticks)
        sounding = speed_at(subticks)
        return tempo if sounding == self.class.speed_of(tempo)

        beats_per_minute = sounding * HeadMusic::Rudiment::Tempo::NANOSECONDS_PER_MINUTE /
          (tempo.ticks_per_beat * HeadMusic::Time::SUBTICKS_PER_TICK)
        HeadMusic::Rudiment::Tempo.new(tempo.beat_value.to_s, beats_per_minute.to_f)
      end
    end
  end
end
