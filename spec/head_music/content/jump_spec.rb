require "spec_helper"

describe HeadMusic::Content::Jump do
  subject(:jump) { described_class.new(:dal_segno, to: :coda) }

  its(:kind) { is_expected.to eq :dal_segno }
  its(:to) { is_expected.to eq :coda }
  its(:to_s) { is_expected.to eq "D.S. al Coda" }
  its(:to_h) { is_expected.to eq("kind" => "dal_segno", "to" => "coda") }

  it { is_expected.to be_dal_segno }
  it { is_expected.not_to be_da_capo }

  it "names no target by default" do
    expect(described_class.new(:da_capo).to).to be_nil
  end

  it "accepts strings" do
    expect(described_class.new("da_capo", to: "fine")).to eq described_class.new(:da_capo, to: :fine)
  end

  it "leaves an absent target out of the hash" do
    expect(described_class.new(:da_capo).to_h).to eq("kind" => "da_capo")
  end

  it "reads back from its hash" do
    expect(described_class.from_h(jump.to_h)).to eq jump
  end

  it "rejects an unknown kind" do
    expect { described_class.new(:dal_signo) }.to raise_error(ArgumentError, /unknown jump kind/)
  end

  it "rejects an unknown target" do
    expect { described_class.new(:da_capo, to: :segno) }.to raise_error(ArgumentError, /unknown jump target/)
  end

  it "validates a copy made with #with" do
    expect { jump.with(to: :bridge) }.to raise_error(ArgumentError)
  end

  describe ".get" do
    {
      "D.C." => [:da_capo, nil],
      "D.C. al Fine" => [:da_capo, :fine],
      "Da Capo al Coda" => [:da_capo, :coda],
      "D.S." => [:dal_segno, nil],
      "dal segno al fine" => [:dal_segno, :fine],
      "D.S. al Coda" => [:dal_segno, :coda]
    }.each do |text, (kind, to)|
      it "reads #{text.inspect}" do
        expect(described_class.get(text)).to eq described_class.new(kind, to: to)
      end
    end

    it "answers nil for other text" do
      expect(described_class.get("To Coda")).to be_nil
    end
  end
end
