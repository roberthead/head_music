module HeadMusic::MIDI
  # The tempos a file writes through each bar, as [offset, microseconds a
  # quarter] pairs, offsets in whole notes from the downbeat. A bar no ramp,
  # fermata, or "a tempo" touches has one step, at its downbeat. Steps also
  # fall at each count under a ramp, at both ends of every ramp and fermata,
  # and at each "a tempo". A step under a ramp takes the average rate over
  # it, so the file's clock agrees with the flow's Conductor at every step;
  # under a fermata the tempo is divided by the stretch.
  class TempoSteps
    BarSplitter = HeadMusic::Notation::BarSplitter

    attr_reader :flow

    def initialize(flow)
      @flow = flow
      @clocks = {}
    end

    # +from+ is where in the bar the steps begin, past a pickup's silence.
    # A ramp or fermata ending on the closing barline adds a step there,
    # the next bar's first.
    def in_bar(bar_number, from: 0)
      return [[from, downbeat_microseconds(bar_number)]] unless touched?(bar_number)

      length = bar_length(bar_number)
      offsets = [from, *breakpoints(bar_number, length).select { |offset| offset > from }].uniq.sort
      offsets.each_with_index.map do |offset, index|
        next [offset, in_bar(bar_number + 1).first.last] if offset == length

        [offset, microseconds(bar_number, offset, offsets[index + 1] || length)]
      end
    end

    # The bars whose steps differ from a single step at the downbeat.
    def touched_bar_numbers
      @touched_bar_numbers ||= items.flat_map { |item| (item.from.bar_number..item.to.ending_bar_number).to_a }.uniq.sort
    end

    private

    def touched?(bar_number)
      touched_bar_numbers.bsearch { |number| number >= bar_number } == bar_number
    end

    def items
      @items ||= [*flow.tempo_ramps, *flow.fermatas, *flow.a_tempos]
    end

    def bar_length(bar_number)
      PerformanceTimeline.bar_length(flow, bar_number)
    end

    def breakpoints(bar_number, length)
      starts = items.map(&:from).select { |position| position.bar_number == bar_number }.map { |position| BarSplitter.offset_in_bar(position) }
      ends = items.map(&:to).filter_map { |position| end_offset(position, bar_number, length) }
      [0, *starts, *ends, *counts_under_ramps(bar_number)]
    end

    def end_offset(position, bar_number, length)
      return BarSplitter.offset_in_bar(position) if position.bar_number == bar_number

      length if position.to_a == [bar_number + 1, 1, 0, 0]
    end

    def counts_under_ramps(bar_number)
      meter = flow.meter_at(bar_number)
      (1...meter.top_number).map { |count| Rational(count, meter.bottom_number) }
        .select { |offset| ramp_at(position(bar_number, offset)) }
    end

    def microseconds(bar_number, offset, finish)
      start = position(bar_number, offset)
      return average_microseconds(start, position(bar_number, finish), finish - offset) if ramp_at(start)

      tempo = offset.zero? ? flow.tempo_at(bar_number) : conductor.tempo_at(start)
      (exact_microseconds(tempo) * stretch_at(start)).round
    end

    def downbeat_microseconds(bar_number)
      Tempo.microseconds_per_quarter(flow.tempo_at(bar_number))
    end

    def average_microseconds(start, finish, length)
      Rational(clock(finish) - clock(start), 1000 * 4 * length).round
    end

    def exact_microseconds(tempo)
      Rational(60_000_000) / (tempo.beats_per_minute.to_r * tempo.beat_value.fraction * 4)
    end

    def ramp_at(position)
      flow.tempo_ramps.find { |ramp| ramp.from <= position && position < ramp.to }
    end

    def stretch_at(position)
      fermata = flow.fermatas.find { |candidate| candidate.from <= position && position < candidate.to }
      fermata ? fermata.stretch.to_r : 1
    end

    def position(bar_number, offset)
      BarSplitter.position_at(flow, bar_number, offset)
    end

    def clock(position)
      @clocks[position.to_a] ||= conductor.musical_to_clock(position).nanoseconds
    end

    def conductor
      @conductor ||= flow.conductor
    end
  end
end
