require "spec_helper"

# MuseScore reads each rendered fixture back as notation. It quantizes what
# it hears, so a tuplet fixture's order is not relied on, only its pitches.
describe "HeadMusic::MIDI" do
  converting = MuseScore.available? && (!ENV["MSCORE"].to_s.empty? || ENV["MUSESCORE_FIXTURES"] == "1")
  fixture_directory = File.expand_path("../../fixtures/notation", __dir__)
  lily_pond = ->(name) { HeadMusic::Notation::LilyPond.parse(File.read(File.join(fixture_directory, "lily_pond", "#{name}.ly"))) }

  fixtures = {
    "ABC CHROMATIC_AIR" => -> { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) },
    "LilyPond bach_invention_01" => -> { lily_pond.call("bach_invention_01") }
  }
  Dir[File.join(fixture_directory, "kern", "*.krn")].sort.each do |path|
    fixtures["kern #{File.basename(path, ".krn")}"] = -> { HeadMusic::Notation::Kern.parse(File.read(path)) }
  end
  %w[marked_da_capo_al_fine marked_dal_segno_al_coda clarinet_changes two_verses].each do |name|
    fixtures["MusicXML #{name}"] = -> { HeadMusic::Notation::MusicXML.parse(File.read(MuseScoreFixtures.path(name, "head_music"))) }
  end
  tuplet_fixtures = {
    "LilyPond tuplets_and_grace_notes" => -> { lily_pond.call("tuplets_and_grace_notes") },
    "kern tuplets" => fixtures.delete("kern tuplets")
  }

  before { skip "set MSCORE, or MUSESCORE_FIXTURES=1 with MuseScore 4 installed, to convert renders through it" unless converting }

  def convert(bytes)
    Dir.mktmpdir("midi") do |directory|
      source = File.join(directory, "render.mid")
      File.binwrite(source, bytes)
      HeadMusic::Notation::MusicXML.parse(MuseScore.convert_file(source, File.join(directory, "converted.musicxml")))
    end
  end

  def rendered_keys(sequence)
    sequence.tracks.drop(1).map { |track| track.notes.sort_by { |note| [note.on, note.key] }.map(&:key) }
  end

  def converted_keys(flow)
    flow.parts.map do |part|
      part.voices.flat_map(&:note_events).flat_map { |voice_event| voice_event.pitches.map { |pitch| [voice_event.position, pitch.midi_note_number] } }.sort.map(&:last)
    end
  end

  fixtures.each do |name, build|
    it "reads #{name} back as the pitches it sounds, in order" do
      bytes = HeadMusic::MIDI.render(build.call)
      sequence = HeadMusic::MIDI::Reader.new(bytes).read
      expect(converted_keys(convert(bytes))).to eq rendered_keys(sequence)
    end
  end

  tuplet_fixtures.each do |name, build|
    it "reads #{name} back as the pitches it sounds" do
      bytes = HeadMusic::MIDI.render(build.call)
      sequence = HeadMusic::MIDI::Reader.new(bytes).read
      expect(converted_keys(convert(bytes)).map(&:sort)).to eq rendered_keys(sequence).map(&:sort)
    end
  end

  it "reads ABC SPEED_THE_PLOUGH, rendered at the smallest division, back as the pitches it sounds, in order" do
    bytes = HeadMusic::MIDI.render(HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH))
    sequence = HeadMusic::MIDI::Reader.new(bytes).read
    expect([sequence.division, converted_keys(convert(bytes))]).to eq [480, rendered_keys(sequence)]
  end
end
