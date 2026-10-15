require "spec_helper"

# Each fixture's decoded notes against keys and onsets worked out here from
# the flow alone: pitches by midi_note_number, onsets by summing each voice's
# rhythmic values, laid out bar by bar in performance order. Notes after
# grace notes start later than written, so they and their grace notes are
# compared by key alone.
describe "HeadMusic::MIDI" do
  fixture_directory = File.expand_path("../../fixtures/notation", __dir__)
  read = ->(path) { File.read(File.join(fixture_directory, path)) }

  fixtures = {
    "ABC SPEED_THE_PLOUGH" => -> { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) },
    "ABC CHROMATIC_AIR" => -> { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) },
    "LilyPond bach_invention_01" => -> { HeadMusic::Notation::LilyPond.parse(read.call("lily_pond/bach_invention_01.ly")) },
    "LilyPond tuplets_and_grace_notes" => -> { HeadMusic::Notation::LilyPond.parse(read.call("lily_pond/tuplets_and_grace_notes.ly")) }
  }
  Dir[File.join(fixture_directory, "kern", "*.krn")].sort.each do |path|
    fixtures["kern #{File.basename(path, ".krn")}"] = -> { HeadMusic::Notation::Kern.parse(File.read(path)) }
  end
  %w[marked_da_capo_al_fine marked_dal_segno_al_coda clarinet_changes two_verses].each do |name|
    fixtures["MusicXML #{name}"] = -> { HeadMusic::Notation::MusicXML.parse(File.read(MuseScoreFixtures.path(name, "head_music"))) }
  end

  def bar_length(flow, bar_number)
    meter = flow.meter_at(bar_number)
    Rational(meter.top_number, meter.bottom_number)
  end

  # Whole notes from the start of bar 1.
  def bar_start(flow, bar_number)
    return (1...bar_number).sum(0) { |number| bar_length(flow, number) } if bar_number >= 1

    -(bar_number..0).sum(0) { |number| bar_length(flow, number) }
  end

  def written_time(position)
    meter = position.meter
    ticks = position.tick + Rational(position.subtick, HeadMusic::Time::SUBTICKS_PER_TICK)
    bar_start(position.flow, position.bar_number) + (position.count - 1 + ticks / meter.ticks_per_count) / meter.bottom_number
  end

  # Voice events run end to end, so each onset is the last plus its length.
  # A rounded position is read only to anchor a voice or to step over a gap.
  def score_times(voice)
    time = nil
    voice.voice_events.map do |voice_event|
      written = written_time(voice_event.position)
      time = written if time.nil? || (time - written).abs > Rational(1, 1024)
      onset = time
      time += voice_event.rhythmic_value.fraction
      [voice_event, onset, time]
    end
  end

  def bar_of(flow, time)
    number = 1
    number -= 1 while bar_start(flow, number) > time
    number += 1 while bar_start(flow, number + 1) <= time
    number
  end

  # Parts playing one instrument throughout share a channel, where notes
  # struck together on a key sound as one.
  def channel_group(part)
    (part.instruments.length == 1) ? part.instruments.first.name_key : part.object_id
  end

  def expected_soundings(flow)
    notes = flow.parts.flat_map do |part|
      part.voices.flat_map { |voice| score_times(voice) }.select { |voice_event, _, _| voice_event.pitched? }.map { |note| [part, *note] }
    end
    by_bar = notes.group_by { |_, _, onset, _| bar_of(flow, onset) }
    file_start = 0
    previous = nil
    flow.performance_order.flat_map do |played_bar|
      number = played_bar.number
      start = bar_start(flow, number)
      window = (number < 1) ? by_bar.fetch(number, []).map { |_, _, onset, _| onset }.min || start : start
      struck = by_bar.fetch(number, []).map { |note| [note, note[2]] }
      unless previous == number - 1
        held = notes.select { |_, _, onset, release| onset < start && release > start }
        struck += held.map { |note| [note, start] }
      end
      soundings = struck.flat_map { |note, onset| soundings_of(*note, file_start + onset - window) }
      file_start += start + bar_length(flow, number) - window
      previous = number
      soundings
    end.uniq
  end

  # A graced sounding's onset is a token that is unique to it.
  def soundings_of(part, voice_event, _onset, _release, at)
    group = channel_group(part)
    return voice_event.pitches.map { |pitch| {key: pitch.midi_note_number, onset: at, group: group} } if voice_event.grace_notes.empty?

    graced_keys(voice_event).each_with_index.map { |key, index| {key: key, onset: [voice_event.object_id, at, index], group: group, graced: true} }
  end

  # A last grace note tied to its main note holds the shared keys through it.
  def graced_keys(voice_event)
    grace_notes = voice_event.grace_notes
    main_keys = voice_event.pitches.map(&:midi_note_number)
    held = grace_notes.last.tied? ? grace_notes.last.pitches.map(&:midi_note_number) & main_keys : []
    grace_notes.flat_map { |grace_note| grace_note.pitches.map(&:midi_note_number) } + (main_keys - held)
  end

  def ticks(time, division)
    (time * 4 * division).round
  end

  fixtures.each do |name, build|
    describe name do
      let(:flow) { build.call }
      let(:sequence) { render_midi(flow) }
      let(:expected) { expected_soundings(flow) }
      let(:graced) { expected.select { |sounding| sounding[:graced] } }
      let(:exact) { (expected - graced).map { |sounding| [sounding[:key], ticks(sounding[:onset], sequence.division)] }.tally }
      let(:decoded) { sequence.notes.map { |note| [note.key, note.on] }.tally }

      it "strikes every ungraced key at its onset" do
        expect(exact.reject { |pair, count| decoded.fetch(pair, 0) >= count }).to eq({})
      end

      it "strikes the keys of graced notes, and nothing else" do
        leftover_keys = decoded.flat_map { |pair, count| [pair.first] * [count - exact.fetch(pair, 0), 0].max }
        expect(leftover_keys.sort).to eq graced.map { |sounding| sounding[:key] }.sort
      end
    end
  end
end
