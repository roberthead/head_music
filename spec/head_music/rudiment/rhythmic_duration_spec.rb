require "spec_helper"

describe HeadMusic::Rudiment::RhythmicDuration do
  let(:value_class) { HeadMusic::Rudiment::RhythmicValue }

  describe ".get" do
    it "reads a single value as a duration of one value" do
      expect(described_class.get("dotted quarter").values.map(&:to_s)).to eq ["dotted quarter"]
    end

    it "reads each tied value in order" do
      expect(described_class.get("half tied to eighth tied to sixteenth").values.map(&:to_s)).to eq %w[half eighth sixteenth]
    end

    it "reads a ratio on each value of its own" do
      expect(described_class.get("triplet eighth tied to quarter").values.map(&:to_s)).to eq ["triplet eighth", "quarter"]
    end

    it "puts a tuplet ratio on every value" do
      expect(described_class.get("quarter tied to eighth", tuplet: "3:2").to_s).to eq "triplet quarter tied to triplet eighth"
    end

    it "reads a symbol" do
      expect(described_class.get(:dotted_half).to_s).to eq "dotted half"
    end

    it "wraps a rhythmic value" do
      expect(described_class.get(value_class.get("triplet eighth")).values).to eq [value_class.get("triplet eighth")]
    end

    it "wraps a rhythmic unit" do
      expect(described_class.get(HeadMusic::Rudiment::RhythmicUnit.get(:whole)).to_s).to eq "whole"
    end

    it "answers a duration as is" do
      duration = described_class.get("half tied to quarter")
      expect(described_class.get(duration)).to equal duration
    end

    it "answers nil for a name it cannot read" do
      expect([described_class.get("garbage"), described_class.get("quarter tied to garbage")]).to eq [nil, nil]
    end

    it "answers nil for nil" do
      expect(described_class.get(nil)).to be_nil
    end

    it "round-trips every ratio, dot count, and tie through its name" do
      durations = [nil, "3:2", "5:4", "7:4"].product([0, 1, 2]).flat_map do |ratio, dots|
        value = described_class.new([value_class.new(:eighth, dots: dots, tuplet: ratio)])
        [value, value.tied_to(:quarter), described_class.get(:half).tied_to(value)]
      end
      expect(durations.reject { |duration| described_class.get(duration.to_s).eql?(duration) }).to be_empty
    end
  end

  describe ".new" do
    it "needs at least one value" do
      expect { described_class.new([]) }.to raise_error(ArgumentError, /at least one/)
    end

    it "holds only rhythmic values" do
      expect { described_class.new([:quarter]) }.to raise_error(ArgumentError, /only rhythmic values/)
    end

    it "is immutable" do
      duration = described_class.get("half tied to eighth")
      expect([duration, duration.values]).to all(be_frozen)
    end
  end

  describe "lengths" do
    subject(:duration) { described_class.get("half tied to eighth") }

    its(:fraction) { is_expected.to eq Rational(5, 8) }
    its(:total_value) { is_expected.to eq 0.625 }
    its(:ticks) { is_expected.to eq HeadMusic::Rudiment::Rhythm::PPQN * 2.5 }

    it "counts subticks once over the whole duration" do
      expect(duration.subticks).to eq value_class.get(:half).subticks + value_class.get(:eighth).subticks
    end

    it "rounds a 7:4 chain once rather than each value" do
      expect(described_class.get("sixteenth tied to sixteenth", tuplet: "7:4").subticks).to eq 65_829
    end
  end

  describe "#single_value" do
    it "answers the lone value of an untied duration" do
      expect(described_class.get("dotted quarter").single_value).to eq value_class.get("dotted quarter")
    end

    it "answers nil for a tied duration" do
      expect(described_class.get("half tied to eighth").single_value).to be_nil
    end
  end

  describe "#tied_to" do
    it "ties a value on at the end" do
      expect(described_class.get("half tied to eighth").tied_to(:quarter).to_s).to eq "half tied to eighth tied to quarter"
    end

    it "ties on another duration's values" do
      expect(described_class.get(:half).tied_to("eighth tied to sixteenth").to_s).to eq "half tied to eighth tied to sixteenth"
    end

    it "leaves the duration it was asked of as it was" do
      duration = described_class.get(:half)
      duration.tied_to(:quarter)
      expect(duration.to_s).to eq "half"
    end

    it "raises on a value it cannot read" do
      expect { described_class.get(:half).tied_to("garbage") }.to raise_error(ArgumentError, /unknown rhythmic duration/)
    end
  end

  describe "tuplet ratios" do
    it "is a tuplet when any value is" do
      expect(described_class.get("quarter tied to triplet eighth")).to be_tuplet
    end

    it "is not a tuplet when no value is" do
      expect(described_class.get("quarter tied to eighth")).not_to be_tuplet
    end

    it "answers the ratio every value shares" do
      expect(described_class.get("triplet quarter tied to triplet eighth").uniform_tuplet_ratio.to_s).to eq "triplet"
    end

    it "answers no shared ratio when the values differ" do
      expect(described_class.get("triplet eighth tied to quarter").uniform_tuplet_ratio).to be_nil
    end

    it "replaces every value's ratio" do
      expect(described_class.get("triplet eighth tied to quarter").with_tuplet("5:4").to_s).to eq "5:4 eighth tied to 5:4 quarter"
    end
  end

  describe "equality" do
    let(:duration) { described_class.get("half tied to eighth") }

    it "equals a duration written the same way" do
      expect(duration).to eq described_class.get("half tied to eighth")
    end

    it "equals its name" do
      expect(duration).to eq "half tied to eighth"
    end

    it "does not equal a rhythmic value written the same way" do
      expect(described_class.get(:quarter) == value_class.get(:quarter)).to be false
    end

    it "does not equal a duration of the same length written another way" do
      expect(described_class.get("dotted half") == described_class.get("half tied to quarter")).to be false
    end

    it "is eql to an equal duration with the same hash" do
      other = described_class.get("half tied to eighth")
      expect([duration.eql?(other), duration.hash == other.hash]).to eq [true, true]
    end

    it "counts equal durations together in tally" do
      durations = %w[half whole half].map { |name| described_class.get(name) }
      expect(durations.tally.transform_keys(&:to_s)).to eq("half" => 2, "whole" => 1)
    end
  end
end
