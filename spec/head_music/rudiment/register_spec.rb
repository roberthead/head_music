require "spec_helper"

describe HeadMusic::Rudiment::Register do
  describe ".get" do
    context "when given an octave number" do
      specify { expect(described_class.get(4)).to eq 4 }
      specify { expect(described_class.get(-1)).to eq(-1) }
      specify { expect(described_class.get(10)).to eq 10 }
      specify { expect(described_class.get("5")).to eq 5 }
    end

    context "when given a bad param" do
      specify { expect(described_class.get("foo")).to eq 4 }
      specify { expect(described_class.get("C")).to eq 4 }
      specify { expect(described_class.get("D")).to eq 4 }
      specify { expect(described_class.get("")).to eq 4 }
      specify { expect(described_class.get(1.5)).to eq 4 }
      specify { expect(described_class.get(15)).to eq 4 }
    end

    context "when given an instance" do
      let(:instance) { described_class.get(4) }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe ".from_name" do
    specify { expect(described_class.from_name("F#5")).to eq 5 }
  end

  describe ".new" do
    it "is private" do
      expect { described_class.new(5) }.to raise_error NoMethodError
    end
  end

  describe "comparison" do
    specify { expect(described_class.get(2)).to be < described_class.get(3) }
    specify { expect(described_class.get(5)).to be > described_class.get(-1) }
    specify { expect(described_class.get(7)).to eq described_class.get("7") }
  end

  describe "addition" do
    specify { expect(described_class.get(4) + 1).to eq described_class.get(5) }
  end

  describe "subtraction" do
    specify { expect(described_class.get(5) - 3).to eq described_class.get(2) }
    specify { expect(described_class.get(4) - 5).to eq described_class.get(-1) }
  end

  describe "helmholtz notation" do
    specify { expect(described_class.get(0).helmholtz_case).to be :upper }
    specify { expect(described_class.get(0).helmholtz_marks).to eq ",," }
    specify { expect(described_class.get(1).helmholtz_case).to be :upper }
    specify { expect(described_class.get(1).helmholtz_marks).to eq "," }
    specify { expect(described_class.get(2).helmholtz_case).to be :upper }
    specify { expect(described_class.get(2).helmholtz_marks).to eq "" }
    specify { expect(described_class.get(3).helmholtz_case).to be :lower }
    specify { expect(described_class.get(3).helmholtz_marks).to eq "" }
    specify { expect(described_class.get(4).helmholtz_case).to be :lower }
    specify { expect(described_class.get(4).helmholtz_marks).to eq "'" }
    specify { expect(described_class.get(5).helmholtz_case).to be :lower }
    specify { expect(described_class.get(5).helmholtz_marks).to eq "''" }
    specify { expect(described_class.get(6).helmholtz_case).to be :lower }
    specify { expect(described_class.get(6).helmholtz_marks).to eq "'''" }
    specify { expect(described_class.get(7).helmholtz_case).to be :lower }
    specify { expect(described_class.get(7).helmholtz_marks).to eq "''''" }
    specify { expect(described_class.get(8).helmholtz_case).to be :lower }
    specify { expect(described_class.get(8).helmholtz_marks).to eq "'''''" }
  end
end
