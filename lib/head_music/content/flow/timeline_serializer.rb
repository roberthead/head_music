class HeadMusic::Content::Flow
  # Writes a timeline as the "timeline" hash of the schema, which
  # HashDeserializer reads back, from the timeline's public readers alone.
  class TimelineSerializer
    delegate :opening_meter, :opening_key_signature_event, :opening_tempo, :meter_changes, :key_signature_changes,
      :tempo_changes, :tempo_ramps, :a_tempos, :fermatas, to: :@timeline

    def initialize(timeline)
      @timeline = timeline
    end

    # Both fields of a key signature event, always: the signature is what is
    # printed at the clef, and the tonal context is the interpretation, and
    # neither derives the other.
    def to_h
      {
        "meter" => opening_meter.to_s,
        **meter_symbol_to_h("meter_symbol", opening_meter),
        "key_signature" => opening_key_signature_event.key_signature.name,
        "tempo" => tempo_to_h(opening_tempo),
        "meter_changes" => meter_changes.map { |bar_number, meter|
          {"number" => bar_number, "meter" => meter.to_s, **meter_symbol_to_h("symbol", meter)}
        },
        "key_signature_changes" => key_signature_changes.map { |bar_number, event|
          {"number" => bar_number, "signature" => event.signature, "tonal_context" => event.tonal_context&.name}
        },
        "tempo_changes" => tempo_changes.map { |bar_number, tempo| {"number" => bar_number, "tempo" => tempo_to_h(tempo)} },
        "tempo_ramps" => tempo_ramps.map { |ramp| tempo_ramp_to_h(ramp) },
        "a_tempos" => a_tempos.map { |a_tempo| {"position" => a_tempo.position.code, "text" => a_tempo.text} },
        "fermatas" => fermatas.map { |fermata| fermata_to_h(fermata) }
      }
    end

    private

    # Two fields rather than a "quarter = 72" string, so that a fractional
    # tempo survives: Tempo.get reads the number by stripping non-digits.
    def tempo_to_h(tempo)
      {"beat_value" => tempo.beat_value.to_s, "beats_per_minute" => tempo.beats_per_minute, "text" => tempo.text}.compact.tap do |hash|
        hash["metronome_mark"] = false unless tempo.metronome_mark?
      end
    end

    def tempo_ramp_to_h(ramp)
      to_tempo = ramp.to_tempo
      {"from" => ramp.from.code, "to" => ramp.to.code, "tempo" => to_tempo && tempo_to_h(to_tempo), "text" => ramp.text}.compact
    end

    def fermata_to_h(fermata)
      stretch = fermata.stretch
      {"from" => fermata.from.code, "to" => fermata.to.code, "stretch" => (stretch == stretch.to_i) ? stretch.to_i : stretch.to_f}
    end

    def meter_symbol_to_h(key, meter)
      meter.symbol ? {key => meter.symbol.to_s} : {}
    end
  end
end
