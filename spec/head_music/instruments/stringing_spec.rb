require "spec_helper"

describe HeadMusic::Instruments::Stringing do
  describe ".for_instrument" do
    context "with a guitar" do
      subject(:stringing) { described_class.for_instrument(:guitar) }

      it "returns a Stringing" do
        expect(stringing).to be_a described_class
      end

      it "has 6 courses" do
        expect(stringing.course_count).to eq 6
      end

      it "has 6 strings (one per course)" do
        expect(stringing.string_count).to eq 6
      end

      it "has the correct standard pitches" do
        pitch_names = stringing.standard_pitches.map(&:to_s)
        expect(pitch_names).to eq %w[E2 A2 D3 G3 B3 E4]
      end
    end

    context "with a twelve-string guitar" do
      subject(:stringing) { described_class.for_instrument(:twelve_string_guitar) }

      it "has 6 courses" do
        expect(stringing.course_count).to eq 6
      end

      it "has 12 strings" do
        expect(stringing.string_count).to eq 12
      end

      it "has doubled courses" do
        expect(stringing.courses.all?(&:doubled?)).to be true
      end
    end

    context "with a violin" do
      subject(:stringing) { described_class.for_instrument(:violin) }

      it "has 4 courses" do
        expect(stringing.course_count).to eq 4
      end

      it "has the correct standard pitches" do
        pitch_names = stringing.standard_pitches.map(&:to_s)
        expect(pitch_names).to eq %w[G3 D4 A4 E5]
      end
    end

    context "with a mandolin" do
      subject(:stringing) { described_class.for_instrument(:mandolin) }

      it "has 4 courses" do
        expect(stringing.course_count).to eq 4
      end

      it "has 8 strings (doubled in unison)" do
        expect(stringing.string_count).to eq 8
      end

      it "has the correct standard pitches" do
        pitch_names = stringing.standard_pitches.map(&:to_s)
        expect(pitch_names).to eq %w[G3 D4 A4 E5]
      end
    end

    context "with an Instrument object" do
      let(:guitar) { HeadMusic::Instruments::Instrument.get(:guitar) }
      subject(:stringing) { described_class.for_instrument(guitar) }

      it "returns a Stringing" do
        expect(stringing).to be_a described_class
      end

      it "has the correct instrument_key" do
        expect(stringing.instrument_key).to eq :guitar
      end
    end

    context "with an unknown instrument" do
      subject(:stringing) { described_class.for_instrument(:kazoo) }

      it { is_expected.to be_nil }
    end
  end

  describe "#instrument" do
    subject(:stringing) { described_class.for_instrument(:guitar) }

    it "returns the instrument" do
      expect(stringing.instrument).to be_a HeadMusic::Instruments::Instrument
      expect(stringing.instrument.name_key).to eq :guitar
    end
  end

  describe "#pitches_with_tuning" do
    let(:stringing) { described_class.for_instrument(:guitar) }
    let(:drop_d) { HeadMusic::Instruments::AlternateTuning.get(:guitar, :drop_d) }

    it "applies the tuning adjustments" do
      pitches = stringing.pitches_with_tuning(drop_d)
      pitch_names = pitches.map(&:to_s)
      expect(pitch_names).to eq %w[D2 A2 D3 G3 B3 E4]
    end
  end

  describe "#==" do
    let(:guitar1) { described_class.for_instrument(:guitar) }
    let(:guitar2) { described_class.for_instrument(:guitar) }
    let(:violin) { described_class.for_instrument(:violin) }

    it "compares by instrument_key and courses" do
      expect(guitar1).to eq guitar2
      expect(guitar1).not_to eq violin
    end

    it "returns false when compared with non-Stringing" do
      expect(guitar1).not_to eq "guitar"
    end
  end

  describe "#to_s" do
    subject { described_class.for_instrument(:guitar) }

    its(:to_s) { is_expected.to eq "6-course stringing for guitar" }
  end
end
