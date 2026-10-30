# Renders a flow to ABC, re-parses the output, and asserts that the
# round trip preserves the musical content.
#
# Durations are compared through DurationWriter's exact Rational arithmetic
# rather than RhythmicValue's Float relative_value.
module ABCRoundTripHelper
  def expect_abc_round_trip(flow)
    rendered = HeadMusic::Notation::ABC.render(flow)
    reparsed = HeadMusic::Notation::ABC.parse(rendered)

    expect(reparsed.key_signature).to eq flow.key_signature
    expect(reparsed.meter.to_s).to eq flow.meter.to_s
    expect(reparsed.name).to eq flow.name
    expect(reparsed.composer).to eq flow.composer
    expect(abc_timeline_changes(reparsed)).to eq abc_timeline_changes(flow)
    expect_named_voices(reparsed, flow) if flow.voices.length > 1

    expect_equivalent_voice_events(reparsed, flow)
  end

  # The meter changes, with their symbols, and the key changes, by bar.
  def abc_timeline_changes(flow)
    [
      flow.meter_changes.transform_values { |meter| [meter.to_s, meter.symbol] },
      flow.key_signature_changes.transform_values { |event| event.key_signature.name }
    ]
  end

  # Each note's grace notes by the order of the note, for a flow whose
  # positions ABC moves, as it does a pickup's.
  def abc_graces_by_note(flow)
    flow.voices.first.note_events.each_with_index.reject { |note_event, _| note_event.grace_notes.empty? }
      .map { |note_event, index| [index, note_event.grace_notes.map { |grace| grace_datum(grace) }] }
  end

  private

  # A voice keeps its role where the role can stand as a V: id; any other is
  # named by its place in the flow.
  def expect_named_voices(reparsed, flow)
    named = flow.voices.each_index.select do |index|
      role = flow.voices[index].role.to_s
      !role.empty? && !role.match?(HeadMusic::Notation::ABC::Writer::UNSAFE_VOICE_ID) && flow.voices.count { |voice| voice.role.to_s == role } == 1
    end
    expect(named.map { |index| reparsed.voices[index].role }).to eq(named.map { |index| flow.voices[index].role })
  end

  # Voice by voice, in order.
  def expect_equivalent_voice_events(reparsed, flow)
    expect(reparsed.voices.length).to eq flow.voices.length
    reparsed.voices.zip(flow.voices).each do |reparsed_voice, voice|
      expect_equivalent_voice(reparsed_voice.voice_events, voice.voice_events)
    end
  end

  def expect_equivalent_voice(reparsed_voice_events, original_voice_events)
    expect(reparsed_voice_events.length).to eq original_voice_events.length

    duration_writer = HeadMusic::Notation::ABC::DurationWriter.new(Rational(1, 8))
    reparsed_voice_events.zip(original_voice_events).each do |actual, expected|
      expect(actual.pitches.sort.map(&:to_s)).to eq expected.pitches.sort.map(&:to_s)
      expect(actual.position.to_s).to eq expected.position.to_s
      expect(duration_writer.multiplier_string(actual.rhythmic_duration))
        .to eq duration_writer.multiplier_string(expected.rhythmic_duration)
    end
  end
end

RSpec.configure do |config|
  config.include ABCRoundTripHelper
end
