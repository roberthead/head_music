require "spec_helper"

describe HeadMusic::Instruments::AlternateTuning do
  describe ".get" do
    context "with Drop D tuning" do
      subject(:tuning) { described_class.get(:guitar, :drop_d) }

      it "returns an AlternateTuning" do
        expect(tuning).to be_a described_class
      end

      it "has the correct instrument_key" do
        expect(tuning.instrument_key).to eq :guitar
      end

      it "has the correct name_key" do
        expect(tuning.name_key).to eq :drop_d
      end

      it "has the correct semitones" do
        expect(tuning.semitones).to eq [-2, 0, 0, 0, 0, 0]
      end
    end

    context "with DADGAD tuning" do
      subject(:tuning) { described_class.get(:guitar, :dadgad) }

      it "has the correct semitones" do
        expect(tuning.semitones).to eq [-2, 0, 0, 0, -2, -2]
      end
    end

    context "with an unknown tuning" do
      subject(:tuning) { described_class.get(:guitar, :unknown_tuning) }

      it { is_expected.to be_nil }
    end

    context "with an unknown instrument" do
      subject(:tuning) { described_class.get(:kazoo, :drop_d) }

      it { is_expected.to be_nil }
    end
  end

  describe ".for_instrument" do
    context "with guitar" do
      subject(:tunings) { described_class.for_instrument(:guitar) }

      it "returns an array of tunings" do
        expect(tunings).to be_an Array
        expect(tunings).to all be_a described_class
      end

      it "includes common tunings" do
        names = tunings.map(&:name_key)
        expect(names).to include(:drop_d, :open_g, :dadgad)
      end
    end

    context "with bass_guitar" do
      subject(:tunings) { described_class.for_instrument(:bass_guitar) }

      it "returns bass tunings" do
        names = tunings.map(&:name_key)
        expect(names).to include(:drop_d, :half_step_down)
      end
    end

    context "with an unknown instrument" do
      subject(:tunings) { described_class.for_instrument(:kazoo) }

      it { is_expected.to eq [] }
    end
  end

  describe "#instrument" do
    subject(:tuning) { described_class.get(:guitar, :drop_d) }

    it "returns the instrument" do
      expect(tuning.instrument).to be_a HeadMusic::Instruments::Instrument
      expect(tuning.instrument.name_key).to eq :guitar
    end
  end

  describe "#name" do
    it "formats the name key as a title" do
      tuning = described_class.get(:guitar, :drop_d)
      expect(tuning.name).to eq "Drop D"
    end

    it "handles multiple words" do
      tuning = described_class.get(:guitar, :half_step_down)
      expect(tuning.name).to eq "Half Step Down"
    end
  end

  describe "#apply_to" do
    let(:stringing) { HeadMusic::Instruments::Stringing.for_instrument(:guitar) }
    let(:tuning) { described_class.get(:guitar, :drop_d) }

    it "returns adjusted pitches" do
      pitches = tuning.apply_to(stringing)
      pitch_names = pitches.map(&:to_s)
      expect(pitch_names).to eq %w[D2 A2 D3 G3 B3 E4]
    end
  end

  describe "#==" do
    let(:drop_d) { described_class.get(:guitar, :drop_d) }
    let(:another_drop_d) { described_class.get(:guitar, :drop_d) }
    let(:open_g) { described_class.get(:guitar, :open_g) }
    let(:bass_drop_d) { described_class.get(:bass_guitar, :drop_d) }

    it "compares by instrument_key and name_key" do
      expect(drop_d).to eq another_drop_d
      expect(drop_d).not_to eq open_g
      expect(drop_d).not_to eq bass_drop_d
    end

    it "returns false when compared with non-AlternateTuning" do
      expect(drop_d).not_to eq "drop_d"
    end
  end

  describe "#to_s" do
    subject { described_class.get(:guitar, :drop_d) }

    its(:to_s) { is_expected.to eq "Drop D (guitar)" }
  end

  describe "applying tunings" do
    let(:stringing) { HeadMusic::Instruments::Stringing.for_instrument(:guitar) }

    context "with Open G tuning" do
      let(:tuning) { described_class.get(:guitar, :open_g) }

      it "produces D-G-D-G-B-D" do
        pitches = tuning.apply_to(stringing)
        pitch_names = pitches.map(&:to_s)
        expect(pitch_names).to eq %w[D2 G2 D3 G3 B3 D4]
      end
    end

    context "with whole step down tuning" do
      let(:tuning) { described_class.get(:guitar, :whole_step_down) }

      it "produces D-G-C-F-A-D" do
        pitches = tuning.apply_to(stringing)
        pitch_names = pitches.map(&:to_s)
        expect(pitch_names).to eq %w[D2 G2 C3 F3 A3 D4]
      end
    end
  end

  describe "partial tuning arrays" do
    let(:stringing) { HeadMusic::Instruments::Stringing.for_instrument(:guitar) }

    context "when tuning has fewer elements than courses" do
      let(:tuning) do
        described_class.new(
          instrument_key: :guitar,
          name_key: :partial,
          semitones: [-2]
        )
      end

      it "treats missing elements as 0" do
        pitches = stringing.pitches_with_tuning(tuning)
        pitch_names = pitches.map(&:to_s)
        expect(pitch_names).to eq %w[D2 A2 D3 G3 B3 E4]
      end
    end
  end
end
