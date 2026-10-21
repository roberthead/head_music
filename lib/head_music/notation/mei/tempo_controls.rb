module HeadMusic::Notation::MEI
  # A <tempo> for each tempo mark after the opening, on the top staff: a
  # change with its text, and its @mm where its number was written; a ramp as
  # <tempo func="continuous"> to its @tstamp2, then its target where it ends;
  # and "a tempo" as text. The opening tempo is the scoreDef's @midi.bpm, and
  # a <tempo> too where it has text. A mark at the final barline is written
  # in the last bar, at the beat after its last.
  class TempoControls
    # A tempo's beat unit is a note value written as @mm.unit and @mm.dots.
    BEAT_UNIT_KEYS = {"dur" => "mm.unit", "dots" => "mm.dots"}.freeze
    QUARTER = HeadMusic::Rudiment::RhythmicValue.get("quarter")

    def initialize(plan)
      @plan = plan
    end

    def controls
      [*opening, *HeadMusic::Notation::TempoMarks.new(flow).filter_map { |mark| mark_element(mark) }]
    end

    private

    attr_reader :plan

    def flow
      plan.flow
    end

    def ids
      plan.ids
    end

    def first_bar
      plan.bar_numbers.first
    end

    # Where the scoreDef's @midi.bpm says all there is: quarters a minute,
    # and no text.
    def opening
      tempo = flow.tempo_at(first_bar)
      return [] unless tempo.text || tempo.beat_value != QUARTER

      [tempo_element(ids.bar_key(first_bar), flow.position(first_bar, 1, 0, 0), tempo)]
    end

    def mark_element(mark)
      position = mark.position
      case mark.kind
      when :tempo
        bar_number = position.bar_number
        tempo_element(ids.bar_key(bar_number), position, mark.tempo) if bar_number > first_bar && plan.bar_numbers.cover?(bar_number)
      when :ramp_end then mark.tempo && tempo_element(ids.position_key(position), position, mark.tempo)
      when :ramp_start then ramp_element(mark)
      when :a_tempo then text_element("atempo-#{ids.position_key(position)}", position, mark.text)
      end
    end

    def tempo_element(key, position, tempo)
      attributes = {**placement(position), "midi.bpm" => plan.midi_bpm(tempo), **metronome_mark(tempo)}
      BarElement.new(bar_of(position), Element.new("tempo", ids.container("tempo", key), attributes, [], tempo.text))
    end

    def metronome_mark(tempo)
      return {} unless tempo.metronome_mark?

      {
        "mm" => Decimals.format(Rational(tempo.beats_per_minute.to_s)),
        **Durations.attributes(tempo.beat_value).transform_keys(BEAT_UNIT_KEYS)
      }
    end

    def ramp_element(mark)
      ramp = flow.tempo_ramps.find { |candidate| candidate.from.to_a == mark.position.to_a }
      attributes = {"func" => "continuous", **placement(ramp.from), "tstamp2" => Tstamp.tstamp2(flow, ramp.from, ramp.to)}
      element = Element.new("tempo", ids.container("tempo", "ramp-#{ids.position_key(ramp.from)}"), attributes, [], mark.text)
      BarElement.new(bar_of(ramp.from), element)
    end

    def text_element(key, position, text)
      BarElement.new(bar_of(position), Element.new("tempo", ids.container("tempo", key), placement(position), [], text))
    end

    def placement(position)
      {"tstamp" => tstamp(position), "staff" => plan.staff_entries.first.number}
    end

    def tstamp(position)
      return Tstamp.beat(flow, position) unless final?(position)

      (flow.meter_at(bar_of(position)).top_number + 1).to_s
    end

    def bar_of(position)
      final?(position) ? flow.last_sounding_bar_number : position.bar_number
    end

    def final?(position)
      position >= flow.final_barline_position
    end
  end

  MeasureWriter.control_sources << TempoControls
end
