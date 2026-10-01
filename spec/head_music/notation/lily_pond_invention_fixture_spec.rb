require "spec_helper"

# Bach's Invention No. 1, BWV 772, from the Bach-Gesellschaft text. Its notes
# match the Mutopia and Humdrum encodings, and its ornaments the 1723
# autograph. The reader drops what the model cannot hold yet: the left hand's
# treble clef in bars 9-12, the fermatas and arpeggios, and the opus number.
describe HeadMusic::Notation::LilyPond do
  subject(:flow) { described_class.parse(File.read(File.expand_path("../../fixtures/notation/lily_pond/bach_invention_01.ly", __dir__))) }

  let(:part) { flow.parts.first }
  let(:right_hand) { part.voices.first }
  let(:left_hand) { part.voices.last }

  def ornamented(voice)
    voice.note_events.filter_map do |note_event|
      "#{note_event.position} #{note_event.ornaments.map(&:name_key).join(" ")}" if note_event.ornaments.any?
    end
  end

  def without_roles(flow)
    flow.voices.map { |voice| voice.to_h.except("role") }
  end

  it "reads one keyboard part with a hand on each staff of a braced grand staff" do
    expect([flow.parts.length, part.voices.map(&:role), part.staff_system.bracket, part.staff_system.staves.map { |staff| staff.clef.name_key }])
      .to eq [1, ["right hand", "left hand"], :brace, %w[treble_clef bass_clef]]
  end

  it "reads the key and the meter" do
    expect([flow.key_signature.name, flow.meter.to_s]).to eq ["C major", "4/4"]
  end

  it "reads every note and rest of both hands" do
    expect(part.voices.map { |voice| [voice.note_events.length, voice.voice_events.length] }).to eq [[238, 251], [217, 224]]
  end

  it "opens with the subject after a sixteenth rest" do
    expect(right_hand.voice_events.first(9).map(&:to_s)).to eq [
      "sixteenth rest at 1:1:000", "sixteenth C4 at 1:1:240", "sixteenth D4 at 1:1:480", "sixteenth E4 at 1:1:720",
      "sixteenth F4 at 1:2:000", "sixteenth D4 at 1:2:240", "sixteenth E4 at 1:2:480", "sixteenth C4 at 1:2:720",
      "eighth G4 at 1:3:000"
    ]
  end

  it "reads the thirty-seconds in bar 6" do
    expect(right_hand.voice_events.select { |voice_event| voice_event.position.to_s.start_with?("6:3") }.map(&:to_s)).to eq [
      "sixteenth D5 at 6:3:000", "thirty-second B4 at 6:3:240", "thirty-second C5 at 6:3:360",
      "sixteenth D5 at 6:3:480", "sixteenth G5 at 6:3:720"
    ]
  end

  it "reads the four Pralltriller and two mordents of the autograph" do
    expect([ornamented(right_hand), ornamented(left_hand)]).to eq [
      ["1:4:000 inverted_mordent", "2:4:000 inverted_mordent", "5:2:000 mordent", "6:4:000 inverted_mordent", "8:1:000 inverted_mordent"],
      ["13:2:000 mordent"]
    ]
  end

  it "fuses a tie across a barline into one voice event" do
    expect(left_hand.voice_events.map(&:to_s)).to include "quarter tied to sixteenth C4 at 4:4:000"
  end

  it "ends both hands on a whole-note chord in bar 22" do
    expect(part.voices.map { |voice| voice.voice_events.last.to_s }).to eq ["whole E4 G4 C5 at 22:1:000", "whole C2 C3 at 22:1:000"]
  end

  it "reads the title and the composer" do
    expect([flow.name, flow.composer]).to eq ["Invention 1", "Johann Sebastian Bach"]
  end

  it "reads back to itself from the LilyPond it writes" do
    expect(described_class.parse(described_class.render(flow)).to_h).to eq flow.to_h
  end

  it "keeps every event through Kern, which has no voice names" do
    expect(without_roles(HeadMusic::Notation::Kern.parse(HeadMusic::Notation::Kern.render(flow)))).to eq without_roles(flow)
  end

  it "writes a MusicXML note for every note, chord tone, tie link, and rest" do
    expect(HeadMusic::Notation::MusicXML.render(flow).scan("<note>").length).to eq 487
  end
end
