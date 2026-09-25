require "spec_helper"

describe HeadMusic::Notation::Kern::Parser do
  describe "the story's example" do
    subject(:flow) { described_class.new(kern).flow }

    let(:kern) do
      <<~KERN
        **kern\t**kern
        *M4/4\t*M4/4
        *k[]\t*k[]
        =1\t=1
        2C\t2e
        2G\t2d
        =2\t=2
        1C\t1c
        ==\t==
        *-\t*-
      KERN
    end

    it "returns a flow" do
      expect(flow).to be_a HeadMusic::Content::Flow
    end

    it "makes a voice of each spine" do
      expect(flow.voices.length).to eq 2
    end

    it "reads the upper spine into the first part" do
      expect(flow.parts.first.voices.first.pitches.map(&:to_s)).to eq %w[E4 D4 C4]
    end

    it "reads the lower spine into the last part" do
      expect(flow.parts.last.voices.first.pitches.map(&:to_s)).to eq %w[C3 G3 C3]
    end

    it "leaves every voice continuous" do
      expect(flow.voices.map(&:first_gap)).to eq [nil, nil]
    end
  end

  it "raises for blank input" do
    expect { described_class.new("").flow }.to raise_error(HeadMusic::Notation::Kern::ParseError, /blank/)
  end

  it "reads CRLF input" do
    expect(described_class.new("**kern\r\n1c\r\n*-\r\n").flow.voices.first.pitches.map(&:to_s)).to eq ["C4"]
  end
end
