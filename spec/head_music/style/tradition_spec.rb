require "spec_helper"

describe HeadMusic::Style::Tradition do
  describe ".get" do
    context "when given :modern" do
      let(:tradition) { described_class.get(:modern) }

      it "returns a ModernTradition instance" do
        expect(tradition).to be_a(HeadMusic::Style::ModernTradition)
      end
    end

    context "when given :standard_practice" do
      let(:tradition) { described_class.get(:standard_practice) }

      it "returns a ModernTradition instance" do
        expect(tradition).to be_a(HeadMusic::Style::ModernTradition)
      end
    end

    context "when given :renaissance_counterpoint" do
      let(:tradition) { described_class.get(:renaissance_counterpoint) }

      it "returns a RenaissanceTradition instance" do
        expect(tradition).to be_a(HeadMusic::Style::RenaissanceTradition)
      end
    end

    context "when given :two_part_harmony" do
      let(:tradition) { described_class.get(:two_part_harmony) }

      it "returns a RenaissanceTradition instance" do
        expect(tradition).to be_a(HeadMusic::Style::RenaissanceTradition)
      end
    end

    context "when given :medieval" do
      let(:tradition) { described_class.get(:medieval) }

      it "returns a MedievalTradition instance" do
        expect(tradition).to be_a(HeadMusic::Style::MedievalTradition)
      end
    end

    context "when given an unknown tradition" do
      let(:tradition) { described_class.get(:unknown) }

      it "returns a ModernTradition instance as default" do
        expect(tradition).to be_a(HeadMusic::Style::ModernTradition)
      end
    end

    context "when given nil" do
      let(:tradition) { described_class.get(nil) }

      it "returns a ModernTradition instance as default" do
        expect(tradition).to be_a(HeadMusic::Style::ModernTradition)
      end
    end
  end

  describe "#consonance_classification" do
    let(:tradition) { described_class.new }
    let(:interval) { instance_double(HeadMusic::Analysis::DiatonicInterval) }

    it "raises AbstractMethodError" do
      expect { tradition.consonance_classification(interval) }.to raise_error(HeadMusic::AbstractMethodError)
    end
  end

  describe "#name" do
    let(:tradition) { HeadMusic::Style::ModernTradition.new }

    it "returns the tradition name as a symbol" do
      expect(tradition.name).to eq(:modern)
    end
  end
end
