require "spec_helper"

describe HeadMusic::Notation::HairpinSegments do
  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nM:4/4\nK:C\nC D E F|G4|\n") }

  def hairpin(kind, from, to)
    HeadMusic::Content::Span.new(flow, kind, from: from, to: to)
  end

  def pieces(hairpins, cuts)
    described_class.split(hairpins, cuts.map { |cut| flow.position(cut) }).map(&:to_s)
  end

  it "cuts a hairpin into touching pieces at each dynamic inside it" do
    expect(pieces([hairpin(:crescendo, "1:1", "2:1")], %w[1:3 1:2 1:3]))
      .to eq ["crescendo from 1:1:000 to 1:2:000", "crescendo from 1:2:000 to 1:3:000", "crescendo from 1:3:000 to 2:1:000"]
  end

  it "leaves a hairpin whole at a dynamic on its start or end" do
    expect(pieces([hairpin(:diminuendo, "1:2", "1:4")], %w[1:2 1:4 2:1])).to eq ["diminuendo from 1:2:000 to 1:4:000"]
  end

  it "cuts each hairpin only where the dynamic falls inside it" do
    expect(pieces([hairpin(:crescendo, "1:1", "1:3"), hairpin(:diminuendo, "1:3", "2:1")], %w[1:2]))
      .to eq ["crescendo from 1:1:000 to 1:2:000", "crescendo from 1:2:000 to 1:3:000", "diminuendo from 1:3:000 to 2:1:000"]
  end
end
