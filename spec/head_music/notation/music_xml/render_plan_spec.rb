require "spec_helper"

describe HeadMusic::Notation::MusicXML::RenderPlan do
  subject(:plan) { described_class.new(composition) }

  let(:composition) do
    composition = HeadMusic::Content::Composition.new(name: "Tune")
    voice = composition.add_voice
    %w[C4 D4 E4 F4].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
    %w[G4 A4 B4 C5].each_with_index { |pitch, index| voice.place("2:#{index + 1}", :quarter, pitch) }
    composition
  end

  let(:voice) { composition.voices.first }

  it "resolves a positive integer divisions value" do
    expect(plan.divisions).to be_a(Integer).and be_positive
  end

  it "spans the composition's bar numbers" do
    expect(plan.bar_numbers).to eq(1..2)
  end

  it "reports the first measure key from the composition key signature" do
    expect(plan.first_measure_key).to include(:fifths, :mode)
  end

  it "groups a voice's placements by bar number" do
    expect(plan.placements_by_bar(voice).keys).to eq [1, 2]
  end

  it "gives a whole-measure rest an integer duration" do
    expect(plan.whole_measure_duration(1)).to be_a(Integer).and be_positive
  end

  context "with a mid-piece meter change authored as a string" do
    let(:composition) do
      composition = HeadMusic::Content::Composition.new
      voice = composition.add_voice
      %w[C4 D4 E4 F4].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
      %w[D5 E5 F5].each_with_index { |pitch, index| voice.place("2:#{index + 1}", :eighth, pitch) }
      composition.change_meter(2, "3/8")
      composition
    end

    before { HeadMusic::Notation::MusicXML::Preflight.check!(composition) }

    it "returns the base meter for bars before the change" do
      expect(plan.effective_meter(1)).to eq composition.meter
    end

    it "returns the changed meter from the change bar onward" do
      changed = plan.effective_meter(2)
      expect([changed.top_number, changed.bottom_number]).to eq [3, 8]
    end
  end

  context "with beamable eighth notes" do
    let(:composition) do
      composition = HeadMusic::Content::Composition.new
      voice = composition.add_voice
      %w[C4 D4 E4 F4 G4 A4 B4 C5].each_with_index { |pitch, index| voice.place("1:#{(index / 2) + 1}:#{(index % 2) * 480}", :eighth, pitch) }
      composition
    end

    it "annotates noteheads with beams" do
      expect(plan.beam_annotations).not_to be_empty
    end
  end
end
