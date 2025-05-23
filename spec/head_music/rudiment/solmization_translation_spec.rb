require "spec_helper"

describe HeadMusic::Rudiment::Solmization do
  describe "translation aliases" do
    context "when looking up by Italian translation" do
      subject(:solfege) { described_class.get("solfeggio") }

      it "finds the solfège system" do
        expect(solfege.name).to eq "solfège"
      end

      its(:syllables) { are_expected.to eq %w[do re mi fa sol la ti] }
    end

    context "when looking up by German translation" do
      subject(:solfege) { described_class.get("Solfège") }

      it "finds the solfège system" do
        expect(solfege.name).to eq "solfège"
      end
    end

    context "when looking up by Spanish translations" do
      subject(:solfege) { described_class.get("solfeo") }

      it "finds the system by solfeo" do
        expect(solfege.name).to eq "solfège"
      end
    end

    context "when looking up by Russian translations" do
      subject(:solfege) { described_class.get("сольфеджио") }

      it "finds the system by сольфеджио" do
        expect(solfege.name).to eq "solfège"
      end
    end

    context "when looking up by Italian solmization translation" do
      subject(:solfege) { described_class.get("solfeggio") }

      it "finds the solfège system" do
        expect(solfege.name).to eq "solfège"
      end
    end
  end
end
