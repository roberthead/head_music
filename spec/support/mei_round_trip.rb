# Renders a flow to MEI, re-parses the output, and asserts that the round
# trip keeps the flow field by field, and that reading is idempotent: the
# reparsed flow renders and reads back to exactly itself.
#
# The comparison is of Flow#to_h, leaving out what the writer does not
# carry or the reader spells another way:
#
# - comments, the source, and the origin;
# - tempo, compared as quarter notes a minute, which is all @midi.bpm holds;
# - an unauthored clef, which counts as the one the writer falls back to,
#   and an unauthored staff system as the one-staff system it writes;
# - a tied chain's spelling, compared by its length, since a note crossing
#   a barline comes back split, and rests joined into runs for the same
#   reason;
# - an authored whole-bar rest at a voice's start or end, which reads back
#   as absence, since the writer writes a voice tacet there the same way;
# - beam breaks, compared as the beams each flow renders;
# - tuplet groups, compared as the brackets a writer draws.
module MEIRoundTripHelper
  def expect_mei_round_trip(flow, **options)
    rendered = HeadMusic::Notation::MEI.render(flow, **options)
    reparsed = HeadMusic::Notation::MEI.parse(rendered)
    expect(mei_music(reparsed)).to eq mei_music(flow)
    expect(mei_beams(HeadMusic::Notation::MEI.render(reparsed, **options))).to eq mei_beams(rendered)
    expect_mei_idempotent(reparsed)
    reparsed
  end

  def expect_mei_idempotent(flow, **options)
    expect(HeadMusic::Notation::MEI.parse(HeadMusic::Notation::MEI.render(flow, **options)).to_h).to eq flow.to_h
  end

  def mei_music(flow)
    hash = flow.to_h
    timeline = hash["timeline"]
    hash.except("source", "comments", "origin").merge(
      "timeline" => timeline.merge(
        "tempo" => mei_quarter_bpm(timeline["tempo"]),
        "tempo_changes" => timeline["tempo_changes"].map { |change| change.merge("tempo" => mei_quarter_bpm(change["tempo"])) }
      ),
      "parts" => flow.parts.zip(hash["parts"]).map { |part, part_hash| mei_part(part, part_hash) }
    )
  end

  # Each note and rest's beam attribute and the <beam>s around it.
  def mei_beams(xml)
    REXML::XPath.match(REXML::Document.new(xml), "//*[local-name()='note' or local-name()='rest' or local-name()='chord']").map do |element|
      depth = REXML::XPath.match(element, "ancestor::*[local-name()='beam']").length
      [element.attributes["beam"], depth]
    end
  end

  private

  def mei_quarter_bpm(tempo_hash)
    return tempo_hash unless tempo_hash

    tempo = HeadMusic::Rudiment::Tempo.new(tempo_hash["beat_value"], tempo_hash["beats_per_minute"])
    (Rational(tempo.beats_per_minute.to_s) * tempo.beat_value.fraction * 4).round(4)
  end

  def mei_part(part, part_hash)
    part_hash.merge(
      "staff_system" => mei_staff_system(part),
      "voices" => part.voices.zip(part_hash["voices"]).map { |voice, voice_hash| mei_voice(voice, voice_hash) }
    )
  end

  def mei_staff_system(part)
    first_bar = part.flow.earliest_bar_number
    system = part.staff_system
    staves = system.staves.map do |staff|
      voice = part.voices.find { |candidate| candidate.staff_at(first_bar).equal?(staff) } || part.voices.first
      clef = staff.clef || HeadMusic::Notation::ClefSelector.for(voice)
      [clef&.name_key&.to_s, staff.clef_changes.transform_values { |change| change.name_key.to_s }, staff.line_count]
    end
    {"bracket" => (staves.length > 1) ? system.bracket.to_s : nil, "staves" => staves}.compact
  end

  def mei_voice(voice, voice_hash)
    voice_hash.except("tuplets").merge(
      "voice_events" => mei_voice_events(voice, voice_hash["voice_events"]),
      "brackets" => mei_brackets(voice)
    ).compact
  end

  def mei_voice_events(voice, voice_event_hashes)
    entries = voice_event_hashes.map do |voice_event_hash|
      voice_event_hash.except("rhythmic_value", "beam_break_before").merge("length" => mei_length(voice_event_hash["rhythmic_value"]))
    end
    entries = mei_without_edge_bar_rests(voice, entries)
    entries.slice_when { |before, after| !(mei_rest?(before) && mei_rest?(after)) }.map do |run|
      run.first.merge("length" => run.sum { |entry| entry["length"] })
    end
  end

  def mei_without_edge_bar_rests(voice, entries)
    whole_bar = ->(entry) { mei_rest?(entry) && mei_whole_bar?(voice.flow, entry) }
    entries.drop_while(&whole_bar).reverse.drop_while(&whole_bar).reverse
  end

  def mei_whole_bar?(flow, entry)
    position = flow.position(entry["position"])
    return false unless position.count == 1 && position.tick.zero? && position.subtick.zero?

    meter = flow.meter_at(position.bar_number)
    entry["length"] == Rational(meter.top_number, meter.bottom_number)
  end

  def mei_rest?(entry)
    entry["sounds"].empty?
  end

  def mei_length(rhythmic_value)
    HeadMusic::Rudiment::RhythmicDuration.get(rhythmic_value).fraction
  end

  def mei_brackets(voice)
    list = HeadMusic::Notation::TupletBrackets.for(voice).map do |bracket|
      last = bracket.last
      [bracket.first.onset, [last.onset.first, last.onset.last + last.rhythmic_value.fraction], bracket.ratio.to_s, bracket.unit.to_s]
    end
    list unless list.empty?
  end
end

RSpec.configure do |config|
  config.include MEIRoundTripHelper
end
