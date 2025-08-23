require "spec_helper"

describe HeadMusic::Rudiment::Alteration do
  describe "::SYMBOLS" do
    specify { expect(described_class::SYMBOLS).to include("♯", "♭", "𝄪", "𝄫", "♮") }
    specify { expect(described_class::SYMBOLS).to include("#", "b", "x", "bb") }
    specify { expect(described_class::SYMBOLS).not_to include("foo") }
  end

  describe ".get" do
    specify { expect(described_class.get("#").identifier).to eq :sharp }
    specify { expect(described_class.get("sharp").identifier).to eq :sharp }
    specify { expect(described_class.get(:sharp).identifier).to eq :sharp }
    specify { expect(described_class.get("\u266F").identifier).to eq :sharp }
    specify { expect(described_class.get("&#9837;").identifier).to eq :flat }

    specify { expect(described_class.get("foo")).to be_nil }
    specify { expect(described_class.get(nil)).to be_nil }
    specify { expect(described_class.get("")).to be_nil }

    context "when given an instance" do
      let(:instance) { described_class.get("#") }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe "#to_s" do
    specify { expect(described_class.get(:sharp)).to eq "♯" }
    specify { expect(described_class.get(:flat)).to eq "♭" }
    specify { expect(described_class.get(:double_sharp)).to eq "𝄪" }
    specify { expect(described_class.get(:double_flat)).to eq "𝄫" }
    specify { expect(described_class.get(:natural)).to eq "♮" }
  end

  describe "#semitones" do
    specify { expect(described_class.get("#").semitones).to eq(1) }
    specify { expect(described_class.get("x").semitones).to eq(2) }
    specify { expect(described_class.get("b").semitones).to eq(-1) }
    specify { expect(described_class.get("bb").semitones).to eq(-2) }
  end

  describe "equality" do
    specify { expect(described_class.get("#")).to eq "♯" }
    specify { expect(described_class.get("bb")).to eq "bb" }
  end

  describe ".by" do
    specify { expect(described_class.by(:cents, 100)).to eq "#" }
    specify { expect(described_class.by(:semitones, 1)).to eq "#" }
    specify { expect(described_class.by(:cents, -100)).to eq "b" }
    specify { expect(described_class.by(:semitones, -1)).to eq :flat }
    specify { expect(described_class.by(:cents, 0)).to eq :natural }
    specify { expect(described_class.by(:semitones, 0)).to eq "♮" }
    specify { expect(described_class.by(:foobars, 12)).to be_nil }
  end

  describe ".symbol?" do
    specify { expect(described_class).to be_symbol("#") }
    specify { expect(described_class).to be_symbol("♯") }
    specify { expect(described_class).not_to be_symbol("j") }
  end

  describe "Named module integration" do
    describe "#name" do
      specify { expect(described_class.get(:sharp).name).to eq "sharp" }
      specify { expect(described_class.get(:flat).name).to eq "flat" }
      specify { expect(described_class.get(:double_sharp).name).to eq "double sharp" }
      specify { expect(described_class.get(:double_flat).name).to eq "double flat" }
      specify { expect(described_class.get(:natural).name).to eq "natural" }
    end

    describe ".get_by_name" do
      specify { expect(described_class.get_by_name("sharp")).to eq described_class.get(:sharp) }
      specify { expect(described_class.get_by_name("flat")).to eq described_class.get(:flat) }
      specify { expect(described_class.get_by_name("natural")).to eq described_class.get(:natural) }
    end
  end

  describe "::MATCHER" do
    specify { expect(described_class::MATCHER).to match "#" }
    specify { expect(described_class::MATCHER).to match "♯" }
    specify { expect(described_class::MATCHER).to match "b" }
    specify { expect(described_class::MATCHER).to match "♭" }
    specify { expect(described_class::MATCHER).to match "x" }
    specify { expect(described_class::MATCHER).to match "𝄪" }
    specify { expect(described_class::MATCHER).to match "bb" }
    specify { expect(described_class::MATCHER).to match "𝄫" }
    specify { expect(described_class::MATCHER).not_to match "h" }
    specify { expect(described_class::MATCHER).not_to match "" }

    specify { expect(described_class::PATTERN).to eq(/♯|\#|♭|b|♮|𝄪|x|𝄫|bb/) }
    specify { expect(described_class::MATCHER).to eq(/♯|\#|♭|b|♮|𝄪|x|𝄫|bb/) }
  end
end
