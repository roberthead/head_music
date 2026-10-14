require "spec_helper"

# An original duet, written for these specs, whose **dynam spines hold the
# hairpin marks kern files carry, read as Verovio 6.3.0 reads them.
describe HeadMusic::Notation::Kern do
  subject(:flow) do
    described_class.parse(File.read(File.expand_path("../../fixtures/notation/kern/hairpins.krn", __dir__)))
  end

  let(:violin) { flow.parts.first }
  let(:cello) { flow.parts.last }

  it "reads the cello's touching hairpins, joined with levels, the last ending on the final barline" do
    expect(cello.spans.map(&:to_s)).to eq [
      "crescendo from 1:1:000 to 2:1:000", "diminuendo from 2:2:000 to 2:4:000", "crescendo from 2:4:000 to 3:1:000",
      "diminuendo from 3:1:000 to 4:1:000", "crescendo from 4:1:000 to 4:3:000", "diminuendo from 4:3:000 to 5:1:000"
    ]
  end

  it "reads the cello's levels beside the marks" do
    expect(cello.dynamic_events.map(&:to_s)).to eq ["p at 1:1:000", "f at 2:1:000", "p at 2:4:000", "mf at 3:1:000"]
  end

  it "reads the violin's hairpins, dropping the crescendo its sforzando interrupts and passing over a stray close" do
    expect(violin.spans.map(&:to_s))
      .to eq ["diminuendo from 1:2:000 to 1:4:000", "crescendo from 2:1:000 to 2:3:000", "crescendo from 4:1:000 to 5:1:000"]
  end

  it "keeps the music within its four bars" do
    expect([flow.latest_bar_number, flow.voices.map { |voice| voice.voice_events.last.to_s }])
      .to eq [4, ["half E5 at 4:3:000", "whole D3 at 4:1:000"]]
  end

  it "renders to MusicXML and LilyPond" do
    expect([flow.to_musicxml, flow.to_lilypond]).to all(be_a(String))
  end
end
