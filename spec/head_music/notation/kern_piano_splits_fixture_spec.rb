require "spec_helper"

# An original grand-staff piano piece, written for these specs, whose right
# hand splits in the middle of a bar, exchanges its sub-spines, joins, splits
# again, and ends one sub-spine early, beside a dynamics spine that splits
# and joins with it.
describe HeadMusic::Notation::Kern do
  subject(:flow) { described_class.parse(File.read(File.expand_path("../../fixtures/notation/kern/piano_splits.krn", __dir__))) }

  let(:part) { flow.parts.first }
  let(:staves) { part.staff_system.staves }

  def placements(voice)
    voice.placements.map(&:to_s)
  end

  it "reads one braced piano part on two staves" do
    expect([flow.parts.length, part.instrument.name_key, part.player.name, staves.length, part.staff_system.bracket])
      .to eq [1, :piano, "Piano", 2, :brace]
  end

  it "reads three voices, reusing the dormant one when the right hand splits again" do
    expect(part.voices.map { |voice| staves.index(voice.staff) }).to eq [0, 0, 1]
  end

  it "keeps the first right-hand voice through the exchange, and rests it while it is joined away" do
    expect(placements(part.voices.first).last(4))
      .to eq ["whole E5 at 3:1:000", "whole rest at 4:1:000", "whole F4 at 5:1:000", "whole rest at 6:1:000"]
  end

  it "pads the voice the first split starts from the flow's first bar" do
    expect(placements(part.voices[1]).first(3)).to eq ["whole rest at 1:1:000", "half rest at 2:1:000", "half E4 at 2:3:000"]
  end

  it "leaves every voice continuous" do
    expect(part.voices.map(&:first_gap)).to eq [nil, nil, nil]
  end

  it "reads back to itself from what it writes" do
    expect(described_class.parse(described_class.render(flow)).to_h).to eq flow.to_h
  end

  it "renders to MusicXML and LilyPond" do
    expect([flow.to_musicxml, flow.to_lilypond]).to all(be_a(String))
  end
end
