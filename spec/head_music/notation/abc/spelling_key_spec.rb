require "spec_helper"

describe HeadMusic::Notation::ABC::SpellingKey do
  subject(:spelling_key) { described_class.new(flow.add_voice) }

  let(:flow) do
    HeadMusic::Content::Flow.new(key_signature: "C major").tap { |flow| flow.change_key_signature(3, "G major") }
  end
  let(:d_major) { HeadMusic::Rudiment::KeySignature.get("D major") }

  it "spells in the flow's key where the voice states none" do
    expect([spelling_key.at(1), spelling_key.at(3)]).to eq [flow.key_signature_at(1), flow.key_signature_at(3)]
  end

  context "with a key stated in bar 1" do
    before { spelling_key.state(d_major, 1) }

    it "spells in the stated key until the flow's key changes" do
      expect(spelling_key.at(2)).to eq d_major
    end

    it "spells in the flow's key from its change on" do
      expect(spelling_key.at(3)).to eq flow.key_signature_at(3)
    end
  end

  context "with a key stated in the bar of the flow's change" do
    before { spelling_key.state(d_major, 3) }

    it "keeps the stated key" do
      expect(spelling_key.at(4)).to eq d_major
    end
  end
end
