require "spec_helper"

# An original duet, written for these specs, with the markings kern files
# carry: articulations and ornaments in the tokens, a sforzando z, and a
# **dynam spine beside each part holding levels, accents, and hairpins.
describe HeadMusic::Notation::Kern do
  subject(:flow) do
    described_class.parse(File.read(File.expand_path("../../fixtures/notation/kern/articulations_ornaments_dynamics.krn", __dir__)))
  end

  let(:flute) { flow.parts.first.voices.first }
  let(:cello) { flow.parts.last.voices.first }

  def marked(voice)
    voice.note_events.filter_map do |note_event|
      marks = [*note_event.articulations, *note_event.ornaments, note_event.note_dynamic].compact.map(&:name_key)
      "#{note_event.position} #{marks.join(" ")}" if marks.any?
    end
  end

  it "reads the flute's articulations, ornaments, and sforzando" do
    expect(marked(flute)).to eq [
      "1:1:000 staccato", "1:2:000 staccato", "1:3:000 staccato", "2:1:000 accent", "3:1:000 trill", "3:3:000 marcato sfz",
      "4:1:000 staccatissimo", "4:3:000 turn", "5:1:000 inverted_mordent", "5:3:000 mordent"
    ]
  end

  it "reads the cello's tenuto and the accents in its dynamics spine" do
    expect(marked(cello)).to eq ["1:1:000 tenuto", "3:1:000 sf", "5:1:000 fp"]
  end

  it "reads each dynamics spine's levels as its part's, skipping hairpins" do
    expect(flow.parts.map { |part| part.dynamic_events.map(&:to_s) })
      .to eq [["mp at 1:1:000", "f at 2:3:000", "p at 5:1:000", "pp at 6:1:000"], ["p at 1:1:000", "mf at 4:1:000", "pp at 6:1:000"]]
  end

  it "puts p in force from the cello's fp" do
    expect(cello.dynamic_at("5:1").name_key).to eq "p"
  end

  it "reads back to itself from what it writes" do
    expect(described_class.parse(described_class.render(flow)).to_h).to eq flow.to_h
  end

  it "renders to MusicXML and LilyPond" do
    expect([flow.to_musicxml, flow.to_lilypond]).to all(be_a(String))
  end
end
