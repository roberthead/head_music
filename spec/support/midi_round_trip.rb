# Compares a flow with what MIDI import reads from its export, as the import
# story judges a round trip: per part, the multiset of each note's onset in
# the file's time, its whole tied length, and its sorted keys; the meter,
# key, tempo, and programs at every bar; the tempo ramps and fermatas; and
# the lyrics. Tempo text, meter symbols, and the boundary between fermatas
# that abut at one stretch are not compared, since MIDI cannot hold them.
# Voices are not compared, since export writes a part's voices to one
# channel, so notes of a part that start and end together count as one
# chord, and a key struck twice at once as one. Spelling is compared apart,
# as the notes spelled otherwise than written.
module MIDIRoundTrip
  module_function

  def music(flow)
    {notes: notes(flow), bars: bars(flow), timeline: timeline(flow), lyrics: lyrics(flow)}
  end

  # Each ramp's ends and the microseconds a quarter of its target, resolved
  # where none is written, and each fermata's ends and stretch, abutting
  # fermatas at one stretch taken as one.
  def timeline(flow)
    ramps = flow.tempo_ramps.empty? ? [] : flow.conductor.tempo_ramps
    {
      ramps: ramps.map { |ramp| [ramp.from.to_a, ramp.to.to_a, HeadMusic::MIDI::Tempo.microseconds_per_quarter(ramp.to_tempo)] },
      fermatas: fermatas(flow)
    }
  end

  def fermatas(flow)
    spans = flow.fermatas.map { |fermata| [fermata.from.to_s, fermata.to.to_s, fermata.stretch] }
    spans.slice_when { |before, after| before[1] != after[0] || before[2] != after[2] }.map { |run| [run.first[0], run.last[1], run.first[2]] }
  end

  def notes(flow)
    each_sounding(flow).map do |part_events|
      chords = part_events.group_by { |onset, voice_event| [onset, voice_event.rhythmic_value.fraction] }
      chords.map { |(onset, length), pairs| [onset, length, pairs.flat_map { |_onset, voice_event| keys(voice_event) }.uniq.sort] }.sort
    end
  end

  def lyrics(flow)
    each_sounding(flow).map do |part_events|
      part_events.flat_map do |onset, voice_event|
        voice_event.syllables.values.map { |syllable| [onset, syllable.text, syllable.hyphen_after?, syllable.verse] }
      end.sort
    end
  end

  # [bar, meter, key fifths, minor?, microseconds a quarter, GM programs].
  def bars(flow)
    (flow.earliest_bar_number..flow.last_sounding_bar_number).map do |bar_number|
      event = flow.timeline.key_signature_event_at(bar_number)
      [
        bar_number, flow.meter_at(bar_number).to_s, fifths(event.signature), minor?(event.tonal_context),
        HeadMusic::MIDI::Tempo.microseconds_per_quarter(flow.tempo_at(bar_number)),
        flow.parts.map { |part| part.instrument_at(bar_number)&.gm_program }
      ]
    end
  end

  # Each track's decoded events by tick, in no order within a tick, since
  # export orders simultaneous notes by voice.
  def events(bytes)
    HeadMusic::MIDI::Reader.new(bytes).read.tracks.map { |track| track.events.group_by(&:tick).transform_values(&:tally) }
  end

  # "part onset key: written → read" for each pitched note spelled
  # otherwise than written, matched by part, onset, and key number.
  def spelling_differences(written, read)
    expected = spellings(written)
    actual = spellings(read)
    expected.flat_map do |(part, onset, key), pitches|
      read_pitches = actual.fetch([part, onset, key], [])
      next [] if read_pitches == pitches

      ["#{part} #{onset} #{key}: #{pitches.join(" ")} → #{read_pitches.join(" ")}"]
    end
  end

  # The flow with its repeats, endings, and jumps taken out, so that it plays
  # as written.
  def without_navigation(flow)
    hash = flow.to_h
    hash["bars"] = hash["bars"].map { |bar| bar.slice("number", "rehearsal_mark") }
    HeadMusic::Content::Flow.from_h(hash)
  end

  # The flow with no dynamics, which export plays as velocities.
  def without_dynamics(flow)
    hash = flow.to_h
    hash["parts"].each do |part|
      part.delete("dynamic_events")
      part["voices"].each { |voice| voice.delete("dynamic_events") }
    end
    HeadMusic::Content::Flow.from_h(hash)
  end

  def spellings(flow)
    input = HeadMusic::Analysis::NoteInput.for(flow)
    hash = flow.to_h
    input.notes.zip(input.addresses).group_by { |note, address| [address[1], note.onset, note.number] }
      .transform_values { |pairs| pairs.map { |_note, address| hash.dig(*address) }.uniq.sort }
  end

  # Per part, [onset, voice event] for each sounded voice event, the onset
  # in whole notes from the file's start, as export lays out the bars: a
  # pickup sounds from its first note.
  def each_sounding(flow)
    starts = HeadMusic::Analysis::NoteInput.for(flow).bar_starts
    flow.parts.map do |part|
      part.voices.flat_map(&:voice_events).select(&:sounded?).map do |voice_event|
        bar_number, offset = HeadMusic::Notation::BarSplitter.exact_start(voice_event)
        [starts.fetch(bar_number) + offset - window(flow, starts, bar_number), voice_event]
      end
    end
  end

  def window(flow, starts, bar_number)
    return 0 if bar_number >= 1

    HeadMusic::MIDI::PerformanceTimeline.bar_length(flow, bar_number) - (starts.fetch(bar_number + 1) - starts.fetch(bar_number))
  end

  def keys(voice_event)
    voice_event.sounds.map { |sound| sound.pitched? ? sound.midi_note_number : HeadMusic::MIDI::SoundKeys.percussion_key_for(sound) }.sort
  end

  def fifths(signature)
    signature -= 12 while signature > 7
    signature += 12 while signature < -7
    signature
  end

  def minor?(tonal_context)
    tonal_context.respond_to?(:qualifier) && HeadMusic::MIDI::ConductorTrack::MINOR_QUALIFIERS.include?(tonal_context.qualifier)
  end
end
