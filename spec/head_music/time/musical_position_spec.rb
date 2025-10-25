require "spec_helper"

describe HeadMusic::Time::MusicalPosition do
  describe ".parse" do
    subject(:position) { described_class.parse(identifier) }

    context "with standard format '1:1:0:0'" do
      let(:identifier) { "1:1:0:0" }

      its(:bar) { is_expected.to eq 1 }
      its(:beat) { is_expected.to eq 1 }
      its(:tick) { is_expected.to eq 0 }
      its(:subtick) { is_expected.to eq 0 }
    end

    context "with '2:3:480:120'" do
      let(:identifier) { "2:3:480:120" }

      its(:bar) { is_expected.to eq 2 }
      its(:beat) { is_expected.to eq 3 }
      its(:tick) { is_expected.to eq 480 }
      its(:subtick) { is_expected.to eq 120 }
    end

    context "with partial positions" do
      context "with '5:2'" do
        let(:identifier) { "5:2" }

        its(:bar) { is_expected.to eq 5 }
        its(:beat) { is_expected.to eq 2 }
        its(:tick) { is_expected.to eq 0 }
        its(:subtick) { is_expected.to eq 0 }
      end

      context "with '3:1:200'" do
        let(:identifier) { "3:1:200" }

        its(:bar) { is_expected.to eq 3 }
        its(:beat) { is_expected.to eq 1 }
        its(:tick) { is_expected.to eq 200 }
        its(:subtick) { is_expected.to eq 0 }
      end
    end
  end

  describe "#initialize" do
    subject(:position) { described_class.new(bar, beat, tick, subtick) }

    context "with default parameters" do
      subject(:position) { described_class.new }

      its(:bar) { is_expected.to eq 1 }
      its(:beat) { is_expected.to eq 1 }
      its(:tick) { is_expected.to eq 0 }
      its(:subtick) { is_expected.to eq 0 }
    end

    context "with specific values" do
      let(:bar) { 3 }
      let(:beat) { 2 }
      let(:tick) { 480 }
      let(:subtick) { 120 }

      its(:bar) { is_expected.to eq 3 }
      its(:beat) { is_expected.to eq 2 }
      its(:tick) { is_expected.to eq 480 }
      its(:subtick) { is_expected.to eq 120 }
    end

    context "with string parameters" do
      let(:bar) { "5" }
      let(:beat) { "4" }
      let(:tick) { "200" }
      let(:subtick) { "50" }

      it "converts strings to integers" do
        expect(position.bar).to eq 5
        expect(position.beat).to eq 4
        expect(position.tick).to eq 200
        expect(position.subtick).to eq 50
      end
    end
  end

  describe "#to_s" do
    subject(:position) { described_class.new(2, 3, 480, 120) }

    it "returns formatted string" do
      expect(position.to_s).to eq "2:3:480:120"
    end
  end

  describe "#to_a" do
    subject(:position) { described_class.new(2, 3, 480, 120) }

    it "returns array of components" do
      expect(position.to_a).to eq [2, 3, 480, 120]
    end
  end

  describe "#normalize!" do
    let(:meter) { HeadMusic::Rudiment::Meter.get("4/4") }

    context "with overflow in subticks" do
      subject(:position) { described_class.new(1, 1, 0, 240) }

      it "carries subticks into ticks" do
        position.normalize!(meter)
        expect(position.bar).to eq 1
        expect(position.beat).to eq 1
        expect(position.tick).to eq 1
        expect(position.subtick).to eq 0
      end

      it "returns self" do
        expect(position.normalize!(meter)).to be position
      end
    end

    context "with overflow in ticks" do
      subject(:position) { described_class.new(1, 1, 960, 0) }

      it "carries ticks into beats" do
        position.normalize!(meter)
        expect(position.bar).to eq 1
        expect(position.beat).to eq 2
        expect(position.tick).to eq 0
        expect(position.subtick).to eq 0
      end
    end

    context "with overflow in beats in 4/4" do
      subject(:position) { described_class.new(1, 4, 0, 0) }

      it "carries beats into bars" do
        position.normalize!(meter)
        expect(position.bar).to eq 2
        expect(position.beat).to eq 0
        expect(position.subtick).to eq 0
      end
    end

    context "with multiple levels of overflow" do
      subject(:position) { described_class.new(1, 1, 960, 240) }

      it "normalizes all levels" do
        position.normalize!(meter)
        expect(position.bar).to eq 1
        expect(position.beat).to eq 2
        expect(position.tick).to eq 1
        expect(position.subtick).to eq 0
      end
    end

    context "with 6/8 meter" do
      let(:meter) { HeadMusic::Rudiment::Meter.get("6/8") }

      context "with overflow in beats" do
        subject(:position) { described_class.new(1, 6, 0, 0) }

        it "carries beats into bars" do
          position.normalize!(meter)
          expect(position.bar).to eq 2
          expect(position.beat).to eq 0
          expect(position.subtick).to eq 0
        end
      end
    end

    context "with negative values" do
      subject(:position) { described_class.new(2, 2, -100, 0) }

      it "handles negative tick overflow" do
        position.normalize!(meter)
        expect(position.bar).to eq 2
        expect(position.beat).to eq 1
        expect(position.tick).to eq 860
        expect(position.subtick).to eq 0
      end
    end

    context "without a meter" do
      subject(:position) { described_class.new(1, 1, 1000, 0) }

      it "returns self without changes" do
        result = position.normalize!(nil)
        expect(result).to be position
        expect(position.tick).to eq 1000
      end
    end
  end

  describe "Comparable" do
    let(:meter) { HeadMusic::Rudiment::Meter.get("4/4") }
    let(:first_bar_first_beat) { described_class.new(1, 1, 0, 0) }
    let(:first_bar_second_beat) { described_class.new(1, 2, 0, 0) }
    let(:also_first_bar_first_beat) { described_class.new(1, 1, 0, 0) }
    let(:second_bar_first_beat) { described_class.new(2, 1, 0, 0) }

    before do
      first_bar_first_beat.normalize!(meter)
      first_bar_second_beat.normalize!(meter)
      also_first_bar_first_beat.normalize!(meter)
      second_bar_first_beat.normalize!(meter)
    end

    it "compares positions correctly" do
      expect(first_bar_first_beat).to eq also_first_bar_first_beat
      expect(first_bar_first_beat).to be < first_bar_second_beat
      expect(first_bar_second_beat).to be > first_bar_first_beat
      expect(first_bar_second_beat).to be < second_bar_first_beat
    end

    it "supports between?" do
      expect(first_bar_second_beat).to be_between(first_bar_first_beat, second_bar_first_beat)
    end

    context "with tick differences" do
      let(:pos_a) { described_class.new(1, 1, 0, 0) }
      let(:pos_b) { described_class.new(1, 1, 100, 0) }
      let(:pos_c) { described_class.new(1, 1, 500, 0) }

      before do
        pos_a.normalize!(meter)
        pos_b.normalize!(meter)
        pos_c.normalize!(meter)
      end

      it "compares by tick values" do
        expect(pos_a).to be < pos_b
        expect(pos_b).to be < pos_c
        expect(pos_c).to be_between(pos_a, described_class.new(1, 2, 0, 0))
      end
    end

    context "with subtick differences" do
      let(:pos_a) { described_class.new(1, 1, 0, 0) }
      let(:pos_b) { described_class.new(1, 1, 0, 100) }

      before do
        pos_a.normalize!(meter)
        pos_b.normalize!(meter)
      end

      it "compares by subtick values" do
        expect(pos_a).to be < pos_b
      end
    end
  end
end
