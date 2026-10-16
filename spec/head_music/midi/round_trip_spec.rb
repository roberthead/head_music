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

  fixtures = {
    "ABC SPEED_THE_PLOUGH, its repeat taken out" => -> { MIDIRoundTrip.without_navigation(HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH)) },
    "ABC CHROMATIC_AIR" => -> { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) },
    "LilyPond bach_invention_01" => -> { HeadMusic::Notation::LilyPond.parse(read.call("lily_pond/bach_invention_01.ly")) },
    "kern satb_chorale, its repeat taken out" => -> { MIDIRoundTrip.without_navigation(kern.call("satb_chorale")) },
    "kern piano_splits, its dynamics taken out" => -> { MIDIRoundTrip.without_dynamics(kern.call("piano_splits")) },
    "MuseScoreFixtures.two_verses, sung once" => -> { first_verse.call(MuseScoreFixtures.two_verses) },
    "MuseScoreFixtures.clarinet_changes" => -> { MuseScoreFixtures.clarinet_changes.flows.first },
    "a drum kit" => drum_kit,
    "an eighth pickup in 3/4" => eighth_pickup
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
