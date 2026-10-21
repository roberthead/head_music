require "spec_helper"

# MIDI Export's fixtures read back by MIDI import, judged as MIDIRoundTrip
# describes: the first read against the written flow, and a second export
# against the first. Each fixture leaves out what export performs rather
# than notates, and the fixtures that cannot leave it out are excluded by
# name, each pinned as still differing so the reason stays true.
describe "HeadMusic::MIDI" do
  fixture_directory = File.expand_path("../../fixtures/notation", __dir__)
  read = ->(path) { File.read(File.join(fixture_directory, path)) }
  kern = ->(name) { HeadMusic::Notation::Kern.parse(read.call("kern/#{name}.krn")) }
  musicxml = ->(name) { HeadMusic::Notation::MusicXML.parse(File.read(MuseScoreFixtures.path(name, "head_music"))) }

  drum_kit = lambda do
    HeadMusic::Content::Flow.new(name: "Backbeat", meter: "4/4").tap do |flow|
      voice = flow.add_part(instrument: "drum_kit").add_voice
      sounds = ->(*names) { names.map { |name| HeadMusic::Rudiment::UnpitchedSound.get(name) } }
      voice.place("1:1", :quarter, sounds.call("bass_drum", "hi_hat"))
      voice.place("1:2", :quarter, sounds.call("snare_drum"))
      voice.place("1:3", :eighth, sounds.call("bass_drum"))
      voice.place("1:3:480", :eighth, sounds.call("bass_drum"))
      voice.place("1:4", :quarter, sounds.call("snare_drum", "hi_hat"))
      voice.place("2:1", :half, sounds.call("crash_cymbal"))
      voice.place("2:3", :half)
    end
  end

  # The ABC reader ignores an anacrusis, so the pickup is placed directly.
  eighth_pickup = lambda do
    HeadMusic::Content::Flow.new(name: "Upbeat", key_signature: "D major", meter: "3/4", tempo: "quarter = 92").tap do |flow|
      voice = flow.add_part(instrument: "violin").add_voice
      voice.place("0:3:480", :eighth, "A4").sing("Up")
      %w[D5 F#5 A5].each.with_index(1) { |pitch, count| voice.place("1:#{count}", :quarter, pitch) }
      voice.place("2:1", :dotted_half, "D5")
    end
  end

  # Export sings verse n on pass n, so a flow played once sings verse 1.
  first_verse = lambda do |flow|
    flow.voices.flat_map(&:note_events).each { |voice_event| voice_event.syllables.delete(2) }
    flow
  end

  tune = ->(meter, music) { HeadMusic::Notation::ABC.parse("X:1\nT:Timeline\nM:#{meter}\nL:1/4\nK:G\n#{music}|]\n") }
  tempo = ->(bpm, beat = "quarter") { HeadMusic::Rudiment::Tempo.new(beat, bpm) }

  rit_then_a_tempo = lambda do
    tune.call("4/4", "GABc|dcBA|GABc|d4").tap do |flow|
      flow.change_tempo(1, tempo.call(120))
      flow.add_tempo_ramp(from: "2:1", to: "3:1", to_tempo: tempo.call(80), text: "rit.")
      flow.add_a_tempo("3:3")
    end
  end

  accel_within_bars = lambda do
    tune.call("3/4", "GAB|cde|dcB|G3").tap do |flow|
      flow.change_tempo(1, tempo.call(72))
      flow.add_tempo_ramp(from: "1:3", to: "3:2", to_tempo: tempo.call(96), text: "accel.")
    end
  end

  mid_bar_fermata = lambda do
    tune.call("3/4", "GAB|cBA|G3").tap do |flow|
      flow.change_tempo(1, tempo.call(100))
      flow.add_fermata("2:2", :quarter)
    end
  end

  final_fermata = lambda do
    tune.call("6/8", "G3|A3").tap do |flow|
      flow.change_tempo(1, tempo.call(60, "dotted quarter"))
      flow.add_fermata("2:1", to: "3:1", stretch: 1.5)
    end
  end

  rit_into_final_fermata = lambda do
    tune.call("4/4", "GABc|dcBA|G4").tap do |flow|
      flow.change_tempo(1, tempo.call(108))
      flow.add_tempo_ramp(from: "2:1", to: "3:1", to_tempo: tempo.call(72), text: "rit.")
      flow.add_fermata("3:1", :whole)
    end
  end

  fixtures = {
    "ABC SPEED_THE_PLOUGH, its repeat taken out" => -> { MIDIRoundTrip.without_navigation(HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH)) },
    "ABC CHROMATIC_AIR" => -> { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) },
    "LilyPond bach_invention_01" => -> { HeadMusic::Notation::LilyPond.parse(read.call("lily_pond/bach_invention_01.ly")) },
    "kern satb_chorale, its repeat taken out" => -> { MIDIRoundTrip.without_navigation(kern.call("satb_chorale")) },
    "kern piano_splits, its dynamics taken out" => -> { MIDIRoundTrip.without_dynamics(kern.call("piano_splits")) },
    "MuseScoreFixtures.two_verses, sung once" => -> { first_verse.call(MuseScoreFixtures.two_verses) },
    "MuseScoreFixtures.clarinet_changes" => -> { MuseScoreFixtures.clarinet_changes.flows.first },
    "a drum kit" => drum_kit,
    "an eighth pickup in 3/4" => eighth_pickup,
    "a rit. ramp, then a tempo in the middle of a bar" => rit_then_a_tempo,
    "an accel. ramp from the middle of a bar to the middle of a later one" => accel_within_bars,
    "a fermata in the middle of a bar" => mid_bar_fermata,
    "a fermata on the final event, at a dotted quarter of 60, stretched 1.5" => final_fermata,
    "a rit. into a fermata on the final event" => rit_into_final_fermata,
    "TimelineExpressionFixtures.melody" => -> { TimelineExpressionFixtures.melody },
    "TimelineExpressionFixtures.chorale" => -> { TimelineExpressionFixtures.chorale }
  }

  excluded = {
    "LilyPond tuplets_and_grace_notes" => ["grace notes take time from their neighbors, and quintuplets and septuplets need an explicit grid:", -> { HeadMusic::Notation::LilyPond.parse(read.call("lily_pond/tuplets_and_grace_notes.ly")) }],
    "kern articulations_ornaments_dynamics" => ["staccato notes are shortened", -> { MIDIRoundTrip.without_dynamics(kern.call("articulations_ornaments_dynamics")) }],
    "kern grace_notes" => ["grace notes take time from their neighbors", -> { kern.call("grace_notes") }],
    "kern hairpins" => ["hairpins become velocities", -> { kern.call("hairpins") }],
    "kern tuplets" => ["quintuplets and septuplets need an explicit grid:", -> { kern.call("tuplets") }],
    "MusicXML marked_da_capo_al_fine" => ["repeats are played out, and accents and hairpins become velocities", -> { musicxml.call("marked_da_capo_al_fine") }],
    "MusicXML marked_dal_segno_al_coda" => ["jumps are played out, and staccato notes are shortened", -> { musicxml.call("marked_dal_segno_al_coda") }]
  }

  fixtures.each do |name, build|
    describe name do
      let(:written) { build.call }
      let(:bytes) { HeadMusic::MIDI.render(written) }
      let(:flow) { HeadMusic::MIDI.parse(bytes) }

      it "reads back the notes, bars, and lyrics written" do
        expect(MIDIRoundTrip.music(flow)).to eq MIDIRoundTrip.music(written)
      end

      it "writes again the events it read" do
        expect(MIDIRoundTrip.events(HeadMusic::MIDI.render(flow))).to eq MIDIRoundTrip.events(bytes)
      end

      it "spells every note as written" do
        expect(MIDIRoundTrip.spelling_differences(written, flow)).to eq []
      end
    end
  end

  # MIDI holds no words and no meter symbols; a tempo's beat it restates
  # as the meter's.
  {melody: "a tempo change at a fermata's end, a ramp into a fermata on a rest, and an a tempo", chorale: "a ramp into a final fermata, counting half notes"}.each do |name, holding|
    it "reads back the timeline of TimelineExpressionFixtures.#{name}, with #{holding}" do
      written = TimelineExpressionFixtures.public_send(name)
      expect_same_timeline(written, HeadMusic::MIDI.parse(HeadMusic::MIDI.render(written)), except: %i[tempo_text meter_symbols])
    end
  end

  describe "a ramp inside a repeat" do
    let(:written) do
      tune.call("4/4", "|:GABc|dcBA:|G4").tap do |flow|
        flow.change_tempo(1, tempo.call(120))
        flow.add_tempo_ramp(from: "1:3", to: "2:3", to_tempo: tempo.call(80), text: "rit.")
      end
    end
    let(:played_out) do
      tune.call("4/4", "GABc|dcBA|GABc|dcBA|G4").tap do |flow|
        flow.change_tempo(1, tempo.call(120))
        flow.add_tempo_ramp(from: "1:3", to: "2:3", to_tempo: tempo.call(80), text: "rit.")
        flow.change_tempo(3, tempo.call(120))
        flow.add_tempo_ramp(from: "3:3", to: "4:3", to_tempo: tempo.call(80), text: "rit.")
      end
    end
    let(:bytes) { HeadMusic::MIDI.render(written) }

    it "reads back a ramp on each pass" do
      expect(MIDIRoundTrip.music(HeadMusic::MIDI.parse(bytes))).to eq MIDIRoundTrip.music(played_out)
    end

    it "writes the same tempos as the repeat played out" do
      expect(MIDIRoundTrip.events(bytes).first).to eq MIDIRoundTrip.events(HeadMusic::MIDI.render(played_out)).first
    end
  end

  excluded.each do |name, (reason, build)|
    it "leaves out #{name}, since #{reason}" do
      written = build.call
      bytes = HeadMusic::MIDI.render(written)
      flow = HeadMusic::MIDI.parse(bytes)
      same = MIDIRoundTrip.music(flow) == MIDIRoundTrip.music(written) && MIDIRoundTrip.events(HeadMusic::MIDI.render(flow)) == MIDIRoundTrip.events(bytes)
      expect(same).to be false
    end
  end
end
