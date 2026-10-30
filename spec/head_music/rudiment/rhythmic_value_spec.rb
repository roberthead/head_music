require "spec_helper"

describe HeadMusic::Rudiment::RhythmicValue do
  describe "constructors" do
    context "when passed as a string" do
      subject(:value) { described_class.get(argument) }

      context "when a sixteenth" do
        let(:argument) { "sixteenth" }

        it { is_expected.to eq :sixteenth }

        its(:ticks) { are_expected.to eq 240 }
        its(:per_whole) { is_expected.to eq 16 }
      end

      context "when a thirty-second" do
        let(:argument) { "thirty-second" }

        it { is_expected.to eq :"thirty-second" }

        its(:ticks) { are_expected.to eq 120 }
        its(:per_whole) { is_expected.to eq 32 }
        its(:name_modifier_prefix) { is_expected.to be_nil }
      end

      context "with a dot" do
        let(:argument) { "dotted eighth" }

        its(:ticks) { are_expected.to eq 720 }
        its(:per_whole) { is_expected.to eq(16 / 3.0) }
        its(:name_modifier_prefix) { is_expected.to eq "dotted" }
      end

      context "with two dots" do
        let(:argument) { "double-dotted eighth" }

        its(:ticks) { are_expected.to eq 840 }
        its(:name_modifier_prefix) { is_expected.to eq "double-dotted" }
      end

      context "with three dots" do
        let(:argument) { "triple-dotted eighth" }

        its(:ticks) { are_expected.to eq 900 }
        its(:name_modifier_prefix) { is_expected.to eq "triple-dotted" }
      end

      context "with abbreviation 'q'" do
        let(:argument) { "q" }

        it { is_expected.to eq described_class.new("quarter") }
      end

      context "with abbreviation 'q.'" do
        let(:argument) { "q." }

        it { is_expected.to be_a(described_class) }
        it { is_expected.to eq described_class.new("quarter", dots: 1) }
      end
    end

    context "when passed a unit and dots" do
      subject(:value) { described_class.new(unit, dots: dots) }

      let(:dots) { nil }

      context "with no dots" do
        subject(:value) { described_class.get(unit) }

        let(:unit) { HeadMusic::Rudiment::RhythmicUnit.get(:quarter) }

        its(:name) { is_expected.to eq "quarter" }
        its(:ticks) { are_expected.to eq 960 }
        its(:relative_value) { is_expected.to eq 1.0 / 4 }
        its(:total_value) { is_expected.to eq 1.0 / 4 }
      end

      context "for a dotted half" do
        let(:unit) { HeadMusic::Rudiment::RhythmicUnit.get(:half) }
        let(:dots) { 1 }

        its(:name) { is_expected.to eq "dotted half" }
        its(:ticks) { are_expected.to eq 960 * 3 }
        its(:relative_value) { is_expected.to eq 3.0 / 4 }
        its(:total_value) { is_expected.to eq 3.0 / 4 }
      end

      context "for a dotted quarter" do
        let(:unit) { HeadMusic::Rudiment::RhythmicUnit.get(:quarter) }
        let(:dots) { 1 }

        its(:name) { is_expected.to eq "dotted quarter" }
        its(:ticks) { are_expected.to eq 1440 }
        its(:relative_value) { is_expected.to eq 1.5 / 4 }
        its(:total_value) { is_expected.to eq 1.5 / 4 }
      end

      context "for a sixteenth" do
        let(:unit) { HeadMusic::Rudiment::RhythmicUnit.get(:sixteenth) }

        its(:name) { is_expected.to eq "sixteenth" }
        its(:ticks) { are_expected.to eq 240 }
        its(:relative_value) { is_expected.to eq 1.0 / 16 }
        its(:total_value) { is_expected.to eq 1.0 / 16 }
      end

      context "for a triple-dotted half" do
        let(:unit) { HeadMusic::Rudiment::RhythmicUnit.get(:half) }
        let(:dots) { 3 }

        its(:name) { is_expected.to eq "triple-dotted half" }
        its(:ticks) { are_expected.to eq 3600 }
        its(:relative_value) { is_expected.to eq(0.5 + 0.25 + 0.125 + 0.0625) }
        its(:total_value) { is_expected.to eq(0.5 + 0.5 / 2 + 0.5 / 4 + 0.5 / 8) }
      end
    end

    it "raises for a unit it does not know" do
      expect { described_class.new(:garbage) }.to raise_error(ArgumentError, /unknown rhythmic unit/)
    end

    it "has no tied value" do
      expect(described_class.new(:half)).not_to respond_to(:tied_value, :tied_chain, :append_tied)
    end
  end

  describe ".get" do
    it "returns nil for a tied name, which is a RhythmicDuration's" do
      expect(described_class.get("half tied to eighth")).to be_nil
    end

    it "returns nil for a name it cannot read" do
      expect(described_class.get("garbage")).to be_nil
    end

    context "with plain and dotted values" do
      it "still parses a plain value" do
        expect(described_class.get("quarter")).to eq described_class.new(:quarter)
      end

      it "still parses a dotted value" do
        expect(described_class.get("dotted quarter")).to eq described_class.new(:quarter, dots: 1)
      end

      it "still parses a double dotted value" do
        expect(described_class.get("double dotted half")).to eq described_class.new(:half, dots: 2)
      end
    end
  end

  describe ".dots_from_words" do
    context "with no 'dotted' in identifier" do
      it "returns 0 for 'quarter'" do
        expect(described_class.dots_from_words("quarter")).to eq 0
      end

      it "returns 0 for 'half'" do
        expect(described_class.dots_from_words("half")).to eq 0
      end

      it "returns 0 for empty string" do
        expect(described_class.dots_from_words("")).to eq 0
      end

      it "returns 0 for 'eighth note'" do
        expect(described_class.dots_from_words("eighth note")).to eq 0
      end
    end

    context "with single 'dotted'" do
      it "returns 1 for 'dotted quarter'" do
        expect(described_class.dots_from_words("dotted quarter")).to eq 1
      end

      it "returns 1 for 'dotted_quarter'" do
        expect(described_class.dots_from_words("dotted_quarter")).to eq 1
      end

      it "returns 1 for 'dotted half'" do
        expect(described_class.dots_from_words("dotted half")).to eq 1
      end

      it "returns 1 for just 'dotted'" do
        expect(described_class.dots_from_words("dotted")).to eq 1
      end
    end

    context "with 'double dotted'" do
      it "returns 2 for 'double dotted quarter'" do
        expect(described_class.dots_from_words("double dotted quarter")).to eq 2
      end

      it "returns 2 for 'double_dotted_quarter'" do
        expect(described_class.dots_from_words("double_dotted_quarter")).to eq 2
      end

      it "returns 2 for 'double-dotted half'" do
        expect(described_class.dots_from_words("double-dotted half")).to eq 2
      end

      it "returns 2 for 'doubly dotted eighth'" do
        expect(described_class.dots_from_words("doubly dotted eighth")).to eq 2
      end

      it "returns 2 for just 'double dotted'" do
        expect(described_class.dots_from_words("double dotted")).to eq 2
      end
    end

    context "with 'triple dotted'" do
      it "returns 3 for 'triple dotted quarter'" do
        expect(described_class.dots_from_words("triple dotted quarter")).to eq 3
      end

      it "returns 3 for 'triple_dotted_quarter'" do
        expect(described_class.dots_from_words("triple_dotted_quarter")).to eq 3
      end

      it "returns 3 for 'triple-dotted half'" do
        expect(described_class.dots_from_words("triple-dotted half")).to eq 3
      end

      it "returns 3 for 'triply dotted eighth'" do
        expect(described_class.dots_from_words("triply dotted eighth")).to eq 3
      end

      it "returns 3 for just 'triple dotted'" do
        expect(described_class.dots_from_words("triple dotted")).to eq 3
      end
    end

    context "with edge cases" do
      it "handles 'dotted' appearing multiple times (takes first modifier)" do
        # The split on "dotted" will take the first part as modifier
        expect(described_class.dots_from_words("triple dotted dotted")).to eq 3
      end

      it "handles case variations (case-sensitive match)" do
        # Regex /dotted/ is case-sensitive, so uppercase doesn't match
        expect(described_class.dots_from_words("DOTTED quarter")).to eq 0
        # Lowercase works
        expect(described_class.dots_from_words("dotted quarter")).to eq 1
      end

      it "handles 'triple' variations with different endings" do
        expect(described_class.dots_from_words("tripled dotted quarter")).to eq 3
      end

      it "handles 'double' variations with different endings" do
        expect(described_class.dots_from_words("doubled dotted quarter")).to eq 2
      end
    end
  end

  describe "value equality" do
    it "collapses equal values in uniq" do
      values = [described_class.get(:quarter), described_class.get("quarter"), described_class.get("dotted quarter")]
      expect(values.uniq.map(&:to_s)).to eq ["quarter", "dotted quarter"]
    end

    it "counts equal values together in tally" do
      values = [described_class.get(:half), described_class.get(:half), described_class.get(:whole)]
      expect(values.tally.transform_keys(&:to_s)).to eq("half" => 2, "whole" => 1)
    end

    it "is eql to an equal value with the same hash" do
      one = described_class.get("dotted quarter")
      other = described_class.get("dotted quarter")
      expect([one.eql?(other), one.hash == other.hash]).to eq [true, true]
    end

    it "is not eql to a string of the same name" do
      expect(described_class.get(:quarter)).not_to eql "quarter"
    end
  end

  describe "tuplet ratios" do
    let(:sixteenth_ratios) { %w[3:2 5:4 6:4 2:3 7:4 9:8] }

    it "names the ratio before the dots" do
      expect(described_class.get(:eighth, tuplet: "3:2").with_tuplet("3:2").to_s).to eq "triplet eighth"
      expect(described_class.get("dotted eighth", tuplet: "3:2").to_s).to eq "triplet dotted eighth"
      expect(described_class.get(:sixteenth, tuplet: "5:4").to_s).to eq "5:4 sixteenth"
    end

    it "reads 'triplet dotted eighth' as dotted once, not triple-dotted" do
      value = described_class.get("triplet dotted eighth")
      expect([value.dots, value.tuplet_ratio.to_s]).to eq [1, "triplet"]
    end

    it "round-trips every ratio and dot count through its name" do
      values = %w[3:2 5:4 6:4 2:3 7:4].product([0, 1, 2, 3]).map { |ratio, dots| described_class.new(:eighth, dots: dots, tuplet: ratio) }
      expect(values.reject { |value| described_class.get(value.to_s).eql?(value) }).to be_empty
    end

    it "is nil for a ratio word whose value does not parse" do
      expect(["triplet blorp", "1:1 eighth", "triplet triplet eighth"].map { |name| described_class.get(name) }).to all(be_nil)
    end

    it "does not read an unnamed tuplet as a plain value" do
      expect(described_class.get("quintuplet eighth")).to be_nil
    end

    it "does not read a tuplet word after the leading ratio word as a plain value" do
      names = ["eighth triplet", "dotted triplet eighth", "quarter tied to eighth triplets", :triplet_eighth, :eighth_triplet]
      expect(names.map { |name| described_class.get(name) }).to all(be_nil)
    end

    it "raises for an unknown ratio given to get" do
      expect { described_class.get(:eighth, tuplet: "quintuplet") }.to raise_error(ArgumentError, /unknown tuplet ratio/)
    end

    it "lands on whole subticks for ratios built from 2, 3, and 5" do
      exact = sixteenth_ratios.first(4).map { |ratio| described_class.get(:sixteenth, tuplet: ratio).exact_subticks }
      expect(exact.map(&:denominator)).to all(eq 1)
    end

    it "gives a 9:8 eighth 102,400 subticks" do
      expect(described_class.get(:eighth, tuplet: "9:8").exact_subticks).to eq 102_400
    end

    it "gives a 7:4 sixteenth an exact fraction of a subtick, rounded once" do
      value = described_class.get(:sixteenth, tuplet: "7:4")
      expect([value.exact_subticks, value.subticks]).to eq [Rational(230_400, 7), 32_914]
    end

    it "keeps the ratio out of the written fraction and in the fraction" do
      value = described_class.get(:quarter, tuplet: "3:2")
      expect([value.written_fraction, value.fraction]).to eq [Rational(1, 4), Rational(1, 6)]
    end

    it "keeps total value and ticks as Floats" do
      value = described_class.get("dotted quarter")
      expect([value.total_value, value.ticks]).to eq [0.375, 1440.0]
    end

    it "compares a triplet sixteenth and a 6:4 sixteenth as the same length but not equal" do
      triplet = described_class.get(:sixteenth, tuplet: "3:2")
      sextuplet = described_class.get(:sixteenth, tuplet: "6:4")
      expect([triplet <=> sextuplet, triplet == sextuplet]).to eq [0, false]
    end

    describe "#tuplet?" do
      it "is true under a ratio" do
        expect(described_class.get("triplet eighth")).to be_tuplet
      end

      it "is false for a plain value" do
        expect(described_class.get("quarter")).not_to be_tuplet
      end
    end
  end
end
