# Renders a flow to kern, re-parses the output, and asserts that the round
# trip keeps the music, and that reading is idempotent: the reparsed flow
# renders and reads back to exactly itself.
#
# Kern cannot say everything a flow can, so the comparison is of the music
# alone. It leaves out what kern has no field for: voice roles, comments,
# beam breaks, the source, any instrument without a kern code, and the work,
# which has specs of its own, and the barline styles kern cannot draw.
# Dynamic events are left to
# expect_same_markings, since kern gives a voice's dynamics to its part. It
# compares a tied chain by its length rather than its spelling, since a note
# crossing a barline comes back split; it drops the rests at either end of a
# voice and joins runs of rests, since the writer pads every spine to the
# flow's length; it compares a tempo in quarter notes per minute; and an
# unauthored clef counts as the one the writer falls back to.
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
      "bar_markings" => kern_bar_markings(flow),
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

  # A repeat sign takes the place of a double or final barline, kern has no
  # dashed or dotted barline, and the final barline at the end is implied.
  def kern_bar_markings(flow)
    bars = flow.to_h["bars"].to_h { |bar| [bar["number"], bar] }
    bars.filter_map do |number, bar|
      barline = kern_barline(bar, bars[number + 1], number == flow.latest_bar_number)
      [number, barline, bar["rehearsal_mark"]] if barline || bar["rehearsal_mark"]
    end
  end

  def kern_barline(bar, following, last)
    return if last || bar["ends_repeat_after_num_plays"] || following&.dig("starts_repeat")

    bar["barline"] if %w[double final].include?(bar["barline"])
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
      "staves" => voice.voice_events.reject(&:rest?).map { |voice_event| staves.index { |staff| staff.equal?(voice.staff_at(voice_event.position.bar_number)) } }.uniq,
      "voice_events" => kern_voice_events(voice)
    }
  end

  def kern_voice_events(voice)
    entries = voice.voice_events.map do |voice_event|
      {
        "position" => voice_event.position.to_s,
        "pitches" => voice_event.pitches.map(&:to_s).sort,
        "length" => voice_event.rhythmic_value.tied_chain.sum { |link| HeadMusic::Notation::DottedDuration.dotted_unit_fraction(link) },
        "syllables" => voice_event.syllables.transform_values(&:to_h),
        "markings" => [voice_event.articulations, voice_event.ornaments, [voice_event.note_dynamic].compact].map { |markings| markings.map(&:name_key) }
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
