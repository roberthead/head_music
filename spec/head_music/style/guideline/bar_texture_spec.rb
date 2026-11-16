require "spec_helper"

describe HeadMusic::Style::Guideline::BarTexture do
  subject(:textures) { described_class.new(voice) }

  let(:voice) do
    HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nc4|c2 d2|c d e f|c2 d e|z4|d2 e2-|e2 f2|]\n").voices.first
  end

  it "classifies each bar by its species texture" do
    expect((1..7).map { |bar| textures[bar] }).to eq %i[whole half quarter florid empty half ligature]
  end

  it "counts only the four species textures as single-species" do
    expect((1..7).map { |bar| textures.single_species?(bar) }).to eq [true, true, true, false, false, true, true]
  end
end
