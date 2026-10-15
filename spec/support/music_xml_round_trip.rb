# Renders a flow to MusicXML, re-parses the output, and asserts that the
# round trip keeps the flow field by field, and that reading is idempotent:
# the reparsed flow renders and reads back to exactly itself.
#
# The comparison is of Flow#to_h, leaving out what MusicXML has no field
# for or the reader names differently:
#
# - voice roles, comments, the source, and the origin;
# - the work beyond its title;
# - an instrument without a sound id, which reads back as none, and
#   instrument changes, which the writer writes only as the <transpose>
#   they bring;
# - beam breaks, compared as the <beam>s each flow renders;
# - tuplet groups, compared as the brackets a writer draws;
# - an unauthored clef, which counts as the one the writer falls back to,
#   and an unauthored staff system as the one-staff system it writes;
# - the part name the writer gives a part with no player;
# - a tied chain's spelling, compared by its length, since a note crossing
#   a barline comes back split;
# - rests, joined into runs, without those at a voice's end, since the
#   reader pads every voice to the flow's end;
# - a phrase mark between two notes, which reads back as a slur;
# - tempo, which waits on Timeline Expressions;
# - the dynamics and hairpins of a one-voice part's voice, which the writer
#   writes with no <voice> and so read back as the part's.
module MusicXMLRoundTripHelper
  def expect_musicxml_round_trip(flow, **options)
    rendered = HeadMusic::Notation::MusicXML.render(flow, **options)
    reparsed = HeadMusic::Notation::MusicXML.parse(rendered)
    unnamed = flow.parts.each_index.reject { |index| flow.parts[index].player }
    expect(musicxml_music(reparsed, unnamed: unnamed)).to eq musicxml_music(flow)
    expect(musicxml_beams(HeadMusic::Notation::MusicXML.render(reparsed, **options))).to eq musicxml_beams(rendered)
    expect_musicxml_idempotent(reparsed)
    reparsed
  end

  def expect_musicxml_idempotent(flow, **options)
    expect(HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(flow, **options)).to_h).to eq flow.to_h
  end

  # The parts at the unnamed indexes drop the name the writer gave them.
  def musicxml_music(flow, unnamed: [])
    hash = flow.to_h
    parts = flow.parts.zip(hash["parts"]).each_with_index.map do |(part, part_hash), index|
      musicxml_part(part, part_hash).tap { |summary| summary.delete("player") if unnamed.include?(index) }
    end
    hash.except("source", "comments", "origin", "part_players").merge(
      "work" => flow.work&.title,
      "timeline" => hash["timeline"].except("tempo", "tempo_changes"),
      "parts" => parts
    )
  end

  def musicxml_beams(xml)
    REXML::XPath.match(REXML::Document.new(xml), "//note").map do |note|
      REXML::XPath.match(note, "beam").map { |beam| "#{beam.attributes["number"]}:#{beam.text}" }.join(" ")
    end
  end

  private

  def musicxml_part(part, part_hash)
    one_voice = part.voices.one?
    voices = part.voices.zip(part_hash["voices"]).map { |voice, voice_hash| musicxml_voice(voice, voice_hash, one_voice) }
    marks = one_voice ? part_hash["voices"].first.slice("dynamic_events", "spans") : {}
    part_hash.except("voices", "player", "instrument_changes").merge(
      "player" => part.player&.name,
      "instrument" => musicxml_instrument(part_hash["instrument"]),
      "staff_system" => musicxml_staff_system(part),
      "dynamic_events" => musicxml_dynamics([*part_hash["dynamic_events"], *marks["dynamic_events"]]),
      "spans" => musicxml_spans(part, [*part_hash["spans"], *marks["spans"]].select { |span| hairpin?(span) }),
      "voices" => voices
    ).compact
  end

  def musicxml_instrument(name_key)
    name_key if HeadMusic::Notation::MusicXML::InstrumentSounds::SOUNDS_BY_NAME_KEY.key?(name_key)
  end

  def musicxml_staff_system(part)
    first_bar = part.flow.earliest_bar_number
    system = part.staff_system
    staves = system.staves.map do |staff|
      voice = part.voices.find { |candidate| candidate.staff_at(first_bar).equal?(staff) }
      clef = staff.clef || HeadMusic::Notation::ClefSelector.for(voice)
      [clef&.name_key&.to_s, staff.clef_changes.transform_values { |change| change.name_key.to_s }]
    end
    {"bracket" => (staves.length > 1) ? system.bracket.to_s : nil, "staves" => staves}.compact
  end

  def musicxml_voice(voice, voice_hash, one_voice)
    spans = voice_hash["spans"].to_a
    spans = spans.reject { |span| hairpin?(span) } if one_voice
    voice_hash.except("role", "tuplets", "dynamic_events", "spans").merge(
      "voice_events" => musicxml_voice_events(voice_hash["voice_events"]),
      "dynamic_events" => one_voice ? nil : musicxml_dynamics(voice_hash["dynamic_events"]),
      "spans" => musicxml_spans(voice, spans),
      "brackets" => musicxml_brackets(voice)
    ).compact
  end

  def musicxml_voice_events(voice_event_hashes)
    entries = voice_event_hashes.map do |voice_event_hash|
      voice_event_hash.except("rhythmic_value", "beam_break_before").merge("length" => musicxml_length(voice_event_hash["rhythmic_value"]))
    end
    joined = entries.slice_when { |before, after| !(rest_entry?(before) && rest_entry?(after)) }.map do |run|
      run.first.merge("length" => run.sum { |entry| entry["length"] })
    end
    joined.reverse.drop_while { |entry| rest_entry?(entry) }.reverse
  end

  def rest_entry?(entry)
    entry["sounds"].empty?
  end

  def musicxml_length(rhythmic_value)
    HeadMusic::Rudiment::RhythmicValue.get(rhythmic_value).tied_chain.sum(&:link_fraction)
  end

  def musicxml_dynamics(dynamic_event_hashes)
    list = dynamic_event_hashes.to_a.sort_by(&:to_a)
    list unless list.empty?
  end

  # A phrase mark between two notes reads back as a slur.
  def musicxml_spans(owner, span_hashes)
    list = span_hashes.to_a.map do |span|
      next span unless span["kind"] == "phrase" && !rest_at?(owner, span["from"]) && !rest_at?(owner, span["to"])

      span.merge("kind" => "slur")
    end
    list = list.sort_by(&:to_a)
    list unless list.empty?
  end

  def rest_at?(voice, position)
    voice.voice_event_at(voice.flow.position(position))&.rest?
  end

  def hairpin?(span_hash)
    %w[crescendo diminuendo].include?(span_hash["kind"])
  end

  def musicxml_brackets(voice)
    list = HeadMusic::Notation::TupletBrackets.for(voice).map do |bracket|
      last = bracket.last
      [bracket.first.onset, [last.onset.first, last.onset.last + last.rhythmic_value.link_fraction], bracket.ratio.to_s, bracket.unit.to_s]
    end
    list unless list.empty?
  end
end

RSpec.configure do |config|
  config.include MusicXMLRoundTripHelper
end
