# Renders a flow to kern, re-parses the output, and asserts that the round
# trip keeps the music, and that reading is idempotent: the reparsed flow
# renders and reads back to exactly itself.
#
# Kern cannot say everything a flow can, so the comparison is of the music
# alone. It leaves out what kern has no field for: voice roles, comments,
# beam breaks, the source, any instrument without a kern code, and the work,
# which has specs of its own. It compares a tied chain by its length rather
# than its spelling, since a note crossing a barline comes back split there;
# it drops the rests at either end of a voice and joins runs of rests, since
# the writer pads every spine to the flow's length; it compares a tempo in
# quarter notes per minute; and an unauthored clef counts as the one the
# writer falls back to.
module KernRoundTripHelper
  def expect_kern_round_trip(flow)
    reparsed = HeadMusic::Notation::Kern.parse(HeadMusic::Notation::Kern.render(flow))
    expect(kern_music(reparsed)).to eq kern_music(flow)
    expect(HeadMusic::Notation::Kern.parse(HeadMusic::Notation::Kern.render(reparsed)).to_h).to eq reparsed.to_h
    reparsed
  end

  private

  def kern_music(flow)
    {
      "name" => flow.name,
      "composer" => flow.composer&.to_s,
      "timeline" => kern_timeline(flow),
      "repeats" => kern_repeats(flow),
      "parts" => flow.parts.map { |part| kern_part(part, flow.earliest_bar_number) }
    }
  end

  def kern_timeline(flow)
    opening = flow.timeline.opening_key_signature_event
    {
      "key" => [opening.signature, opening.tonal_context&.name],
      "key_changes" => flow.key_signature_changes.transform_values { |event| [event.signature, event.tonal_context&.name] },
      "meter" => flow.meter.to_s,
      "meter_changes" => flow.meter_changes.transform_values(&:to_s),
      "tempo" => HeadMusic::Notation::Kern::TempoReader.tempo_field(flow.tempo),
      "tempo_changes" => flow.tempo_changes.transform_values { |tempo| HeadMusic::Notation::Kern::TempoReader.tempo_field(tempo) }
    }
  end

  def kern_repeats(flow)
    flow.to_h["bars"].map { |bar| [bar["number"], !!bar["starts_repeat"], !!bar["ends_repeat_after_num_plays"]] }
      .reject { |_number, starts, ends| !starts && !ends }
  end

  def kern_part(part, first_bar)
    staves = part.staff_system.staves
    voices = part.voices.sort_by.with_index { |voice, index| [staves.index { |staff| staff.equal?(voice.staff_at(first_bar)) }, index] }
    {
      "player" => part.player&.name,
      "instrument" => HeadMusic::Notation::Kern::InstrumentCodes.code_field(part.instrument),
      "clefs" => staves.map { |staff| kern_clef(staff, voices, first_bar) },
      "voices" => voices.map { |voice| kern_voice(voice, staves) }
    }
  end

  def kern_clef(staff, voices, first_bar)
    clef = staff.clef_at(first_bar) || HeadMusic::Notation::ClefSelector.for(voices.find { |voice| voice.staff_at(first_bar).equal?(staff) })
    [clef.name_key.to_s, staff.clef_changes.transform_values { |change| change.name_key.to_s }]
  end

  def kern_voice(voice, staves)
    {
      "staves" => voice.placements.reject(&:rest?).map { |placement| staves.index { |staff| staff.equal?(voice.staff_at(placement.position.bar_number)) } }.uniq,
      "placements" => kern_placements(voice)
    }
  end

  def kern_placements(voice)
    entries = voice.placements.map do |placement|
      {
        "position" => placement.position.to_s,
        "pitches" => placement.pitches.map(&:to_s).sort,
        "length" => placement.rhythmic_value.tied_chain.sum { |link| HeadMusic::Notation::DottedDuration.dotted_unit_fraction(link) },
        "syllables" => placement.syllables.transform_values(&:to_h)
      }
    end
    joined = entries.slice_when { |before, after| !(before["pitches"].empty? && after["pitches"].empty?) }.map do |run|
      run.first.merge("length" => run.sum { |entry| entry["length"] })
    end
    joined.drop_while { |entry| entry["pitches"].empty? }.reverse.drop_while { |entry| entry["pitches"].empty? }.reverse
  end
end

RSpec.configure do |config|
  config.include KernRoundTripHelper
end
