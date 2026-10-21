require "spec_helper"

describe HeadMusic::Notation::ABC::RenderPlan do
  subject(:plan) { described_class.new(flow) }

  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nT:Plan\nM:4/4\nL:1/8\nK:G\nGABc dedB|]\n") }

  it "renders the opening key as a K: value" do
    expect(plan.first_measure_key.to_s).to eq "G"
  end

  it "carries the key signature the pitches are spelled in" do
    expect(plan.first_measure_key.key_signature).to eq HeadMusic::Rudiment::KeySignature.get("G major")
  end

  context "with a modal key" do
    let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nT:Plan\nM:4/4\nL:1/8\nK:Ador\nABcd efga|]\n") }

    it "names the mode" do
      expect(plan.first_measure_key.to_s).to eq "Ador"
    end
  end

  it "renders a key change as a K: value at its bar" do
    flow.voices.first.place("2:1", :whole, "D5")
    flow.change_key_signature(2, "D major")
    expect(plan.measure_key_changes.transform_values(&:to_s)).to eq(2 => "D")
  end

  context "when transposed for a B-flat clarinet" do
    subject(:plan) { described_class.new(flow, transposed: true) }

    let(:flow) do
      HeadMusic::Notation::ABC.parse("X:1\nT:Plan\nM:4/4\nL:1/8\nK:C\nCDEF GABc|]\n").tap do |flow|
        flow.parts.first.change_instrument(1, "clarinet")
      end
    end

    it "renders the part's written key" do
      expect(plan.first_measure_key(flow.parts.first).to_s).to eq "D"
    end

    it "renders the sounding key for no part" do
      expect(plan.first_measure_key.to_s).to eq "C"
    end
  end

  it "refuses a key no K: field can name, before any writing" do
    flow.change_key_signature(1, "C harmonic_minor")
    expect { plan }.to raise_error HeadMusic::Notation::ABC::RenderError, /scale type/
  end
end
