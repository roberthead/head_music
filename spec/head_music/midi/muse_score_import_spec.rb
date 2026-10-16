require "spec_helper"

# MuseScore's MIDI exports of the MusicXML fixtures, read by MIDI import and
# compared with MusicXML.parse of the same file: each part's pitches, spelled,
# in the order they sound. MuseScore writes a track for each staff, so the
# imported parts that share a name are taken together. Its known losses are
# pinned, and fixtures it plays otherwise than written are excluded by name,
# each pinned as still differing.
describe "HeadMusic::MIDI" do
  converting = MuseScore.available? && (!ENV["MSCORE"].to_s.empty? || ENV["MUSESCORE_FIXTURES"] == "1")

  excluded = {
    "bach_invention_01" => "MuseScore plays each mordent as the notes it stands for",
    "marked_dal_segno_al_coda" => "MuseScore plays each ornament as the notes it stands for",
    "marked_da_capo_al_fine" => "MuseScore does not play the D.C. al Fine",
    "grace_notes_before_downbeat" => "MuseScore plays the grace notes as notes",
    "clarinet_changes_transposed" => "MuseScore keeps the first clarinet's transposition through the instrument changes"
  }

  before { skip "set MSCORE, or MUSESCORE_FIXTURES=1 with MuseScore 4 installed, to convert renders through it" unless converting }

  def import(source)
    Dir.mktmpdir("midi") do |directory|
      HeadMusic::MIDI.parse(MuseScore.convert_file(source, File.join(directory, "converted.mid"), timeout: 60))
    end
  end

  def import_musicxml(musicxml)
    Dir.mktmpdir("musicxml") do |directory|
      source = File.join(directory, "source.musicxml")
      File.write(source, musicxml)
      import(source)
    end
  end

  # [time, key number, pitch] for each pitch a part sounds, bars laid end to
  # end in performance order.
  def soundings(flow, part)
    time = 0
    plays = flow.performance_order.map { |bar| [bar.number, time].tap { time += HeadMusic::MIDI::PerformanceTimeline.bar_length(flow, bar.number) } }
    by_bar = part.voices.flat_map(&:note_events).group_by { |voice_event| HeadMusic::Notation::BarSplitter.exact_start(voice_event).first }
    plays.flat_map do |bar_number, start|
      by_bar.fetch(bar_number, []).flat_map do |voice_event|
        offset = HeadMusic::Notation::BarSplitter.exact_start(voice_event).last
        voice_event.pitches.map { |pitch| [start + offset, pitch.midi_note_number, pitch.to_s] }
      end
    end
  end

  def pitches(flow)
    flow.parts.map { |part| soundings(flow, part).sort.map(&:last) }
  end

  def imported_pitches(flow)
    flow.parts.group_by { |part| (part.player || part.instrument)&.name }.values.map do |parts|
      parts.flat_map { |part| soundings(flow, part) }.sort.map(&:last)
    end
  end

  (MuseScoreFixtures.names - excluded.keys).each do |name|
    it "reads #{name} as the pitches it sounds, in order" do
      written = HeadMusic::Notation::MusicXML.parse(File.read(MuseScoreFixtures.path(name, "head_music")))
      expect(imported_pitches(import(MuseScoreFixtures.path(name, "head_music")))).to eq pitches(written)
    end
  end

  excluded.each do |name, reason|
    it "leaves out #{name}, since #{reason}" do
      written = HeadMusic::Notation::MusicXML.parse(File.read(MuseScoreFixtures.path(name, "head_music")))
      expect(imported_pitches(import(MuseScoreFixtures.path(name, "head_music")))).not_to eq pitches(written)
    end
  end

  it "reads two_verses with the pickup head_music's MusicXML pads into a full first bar" do
    flow = import(MuseScoreFixtures.path("two_verses", "head_music"))
    expect(bar_events(flow.voices.first).first(2)).to eq [["1:1:000", "half", "rest"], ["1:3:000", "quarter", "C4"]]
  end

  it "reads clarinet_changes_transposed at the first clarinet's transposition throughout" do
    flow = import(MuseScoreFixtures.path("clarinet_changes_transposed", "head_music"))
    expect(imported_pitches(flow)).to eq [%w[C4 D4 F4 G♭4 F4 G4]]
  end

  describe "a tune in A minor" do
    let(:written) { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) }
    let(:flow) { import_musicxml(HeadMusic::Notation::MusicXML.render(written)) }

    it "reads MuseScore's major signature as C major" do
      expect([written.timeline.tonal_context_at(1).name, flow.timeline.tonal_context_at(1).name]).to eq ["A minor", "C major"]
    end

    it "costs no spelling" do
      expect([imported_pitches(flow), MIDIRoundTrip.spelling_differences(written, flow)]).to eq [pitches(written), []]
    end
  end
end
