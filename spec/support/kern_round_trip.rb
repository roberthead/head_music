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

  # Kern writes what sounds and no brackets, so a tuplet round trip compares
  # each written link's exact onset, its value under the ratio the reader
  # maps its length to (a 6:4 sixteenth comes back a triplet sixteenth, a
  # duplet a dotted value), and its pitches; the groups TupletGroups infers
  # from the original's values; and the grace notes.
  def expect_kern_tuplet_round_trip(flow)
    reparsed = expect_kern_round_trip(flow)
    expect(kern_links(reparsed)).to eq kern_links(flow)
    expect(kern_groups(reparsed)).to eq inferred_kern_groups(flow)
    expect_same_grace_notes(flow, reparsed)
    reparsed
  end

  private

  # Per voice, each written link as [exact onset, canonical value, pitches],
  # without the rests at either end that the writer pads.
  def kern_links(flow)
    flow.voices.map do |voice|
      links = kern_link_entries(voice).map { |onset, link, voice_event| [onset, canonical_kern_value(link).to_s, voice_event.pitches.map(&:to_s).sort] }
      links.drop_while { |*, pitches| pitches.empty? }.reverse.drop_while { |*, pitches| pitches.empty? }.reverse
    end
  end

  def kern_link_entries(voice)
    voice.voice_events.flat_map do |voice_event|
      HeadMusic::Notation::BarSplitter.segments_of(voice_event).flat_map do |segment|
        offset = segment.offset
        segment.rhythmic_value.tied_chain.map do |link|
          [exact_point(segment.bar_number, offset), link, voice_event].tap { offset += link.link_fraction }
        end
      end
    end
  end

  def canonical_kern_value(link)
    recip, dots = HeadMusic::Notation::Kern::DurationWriter.token(link).match(/\A([\d%]+)(\.*)\z/).captures
    HeadMusic::Notation::Kern::DurationReader.duration(recip, dots).rhythmic_value
  end

  # Per voice, each group as [exact start, ratio, exact length].
  def kern_groups(flow)
    flow.voices.map do |voice|
      voice.tuplets.map do |group|
        events = group.voice_events
        start = exact_point(events.first.position.bar_number, HeadMusic::Notation::BarSplitter.onset_in_bar(events.first))
        [start, group.ratio.to_s, events.sum { |voice_event| voice_event.rhythmic_value.fraction }]
      end
    end
  end

  # The groups the reader infers from what the writer writes: a rest as one
  # rest per written link, and each value under its canonical ratio.
  def inferred_kern_groups(flow)
    flow.voices.map do |voice|
      items = kern_reader_items(voice)
      HeadMusic::Notation::Kern::TupletGroups.runs(items.map(&:last)).map do |run|
        [items[run.first].first, items[run.first].last.ratio.to_s, items[run].sum { |_, item| item.fraction }]
      end
    end
  end

  def kern_reader_items(voice)
    kern_link_entries(voice).slice_when { |before, after| after[2].rest? || before[2].rest? || !after[2].equal?(before[2]) }.map do |entries|
      values = entries.map { |_, link, _| canonical_kern_value(link) }
      ratios = values.map(&:tuplet_ratio).uniq
      fraction = values.sum(&:fraction)
      [entries.first.first, HeadMusic::Notation::Kern::TupletGroups::Item.new((ratios.length == 1) ? ratios.first : nil, fraction)]
    end
  end

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
        "length" => voice_event.rhythmic_value.fraction,
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
