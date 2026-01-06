require "spec_helper"

describe HeadMusic::Instruments::Stringing do
  describe ".for_instrument" do
    context "with a symbol" do
      subject(:stringing) { described_class.for_instrument(:guitar) }

      it "returns a Stringing" do
        expect(stringing).to be_a described_class
      end

      it "has the correct instrument_key" do
        expect(stringing.instrument_key).to eq :guitar
      end
    end

    context "with a string" do
      subject(:stringing) { described_class.for_instrument("guitar") }

      it "returns a Stringing" do
        expect(stringing).to be_a described_class
      end

      it "has the correct instrument_key" do
        expect(stringing.instrument_key).to eq :guitar
      end
    end

    context "with an Instrument object" do
      subject(:stringing) { described_class.for_instrument(guitar) }

      let(:guitar) { HeadMusic::Instruments::Instrument.get(:guitar) }

      it "returns a Stringing" do
        expect(stringing).to be_a described_class
      end

      it "has the correct instrument_key" do
        expect(stringing.instrument_key).to eq :guitar
      end
    end

    context "with an Instrument object that has no stringing but has a parent with stringing" do
      # baritone_ukulele has its own stringing, so we need a different approach
      # Let's test with an instrument that has a parent
      let(:parent_instrument) { HeadMusic::Instruments::Instrument.get(:violin) }
      let(:child_instrument) do
        # Create a mock child instrument without its own stringing
        instance_double(
          HeadMusic::Instruments::Instrument,
          name_key: :fake_violin_variant,
          parent: parent_instrument
        )
      end

      it "falls back to parent stringing when child has none" do
        allow(child_instrument).to receive(:is_a?).with(HeadMusic::Instruments::Instrument).and_return(true)

        stringing = described_class.for_instrument(child_instrument)
        expect(stringing).to be_a described_class
        expect(stringing.course_count).to eq 4
      end
    end

    context "with an Instrument object that has no stringing and no parent" do
      subject(:stringing) { described_class.for_instrument(trumpet) }

      let(:trumpet) { HeadMusic::Instruments::Instrument.get(:trumpet) }

      it { is_expected.to be_nil }
    end

    context "with an Instrument object that has no stringing and parent has no stringing" do
      # Create a mock instrument with a parent that also has no stringing
      let(:parent) do
        instance_double(HeadMusic::Instruments::Instrument, name_key: :fake_parent)
      end
      let(:child) do
        instance_double(
          HeadMusic::Instruments::Instrument,
          name_key: :fake_child,
          parent: parent
        )
      end

      it "returns nil" do
        allow(child).to receive(:is_a?).with(HeadMusic::Instruments::Instrument).and_return(true)

        stringing = described_class.for_instrument(child)
        expect(stringing).to be_nil
      end
    end

    context "with an unknown instrument symbol" do
      subject(:stringing) { described_class.for_instrument(:kazoo) }

      it { is_expected.to be_nil }
    end

    context "with a guitar" do
      subject(:stringing) { described_class.for_instrument(:guitar) }

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
  end

  describe "#instrument" do
    subject(:stringing) { described_class.for_instrument(:guitar) }

    it "returns the instrument" do
      expect(stringing.instrument).to be_a HeadMusic::Instruments::Instrument
      expect(stringing.instrument.name_key).to eq :guitar
    end
  end

  describe "#course_count" do
    it "returns the number of courses" do
      expect(described_class.for_instrument(:guitar).course_count).to eq 6
      expect(described_class.for_instrument(:bass_guitar).course_count).to eq 4
      expect(described_class.for_instrument(:ukulele).course_count).to eq 4
    end
  end

  describe "#string_count" do
    it "returns the total number of physical strings" do
      expect(described_class.for_instrument(:guitar).string_count).to eq 6
      expect(described_class.for_instrument(:twelve_string_guitar).string_count).to eq 12
      expect(described_class.for_instrument(:mandolin).string_count).to eq 8
    end
  end

  describe "#standard_pitches" do
    it "returns an array of Pitch objects" do
      stringing = described_class.for_instrument(:guitar)
      expect(stringing.standard_pitches).to all be_a HeadMusic::Rudiment::Pitch
    end
  end

  describe "#pitches_with_tuning" do
    let(:stringing) { described_class.for_instrument(:guitar) }

    context "with a full tuning array" do
      let(:drop_d) { HeadMusic::Instruments::AlternateTuning.get(:guitar, :drop_d) }

      it "applies the tuning adjustments" do
        pitches = stringing.pitches_with_tuning(drop_d)
        pitch_names = pitches.map(&:to_s)
        expect(pitch_names).to eq %w[D2 A2 D3 G3 B3 E4]
      end
    end

    context "with a partial tuning array (fewer elements than courses)" do
      let(:partial_tuning) do
        HeadMusic::Instruments::AlternateTuning.new(
          instrument_key: :guitar,
          name_key: :partial,
          semitones: [-2]
        )
      end

      it "treats missing elements as 0" do
        pitches = stringing.pitches_with_tuning(partial_tuning)
        pitch_names = pitches.map(&:to_s)
        expect(pitch_names).to eq %w[D2 A2 D3 G3 B3 E4]
      end
    end

    context "with an empty tuning array" do
      let(:empty_tuning) do
        HeadMusic::Instruments::AlternateTuning.new(
          instrument_key: :guitar,
          name_key: :empty,
          semitones: []
        )
      end

      it "returns standard pitches unchanged" do
        pitches = stringing.pitches_with_tuning(empty_tuning)
        pitch_names = pitches.map(&:to_s)
        expect(pitch_names).to eq %w[E2 A2 D3 G3 B3 E4]
      end
    end
  end

  describe "#==" do
    let(:guitar_instance) { described_class.for_instrument(:guitar) }
    let(:another_guitar) { described_class.for_instrument(:guitar) }
    let(:violin) { described_class.for_instrument(:violin) }

    it "returns true for equal stringings" do
      expect(guitar_instance).to eq another_guitar
    end

    it "returns false for different instruments" do
      expect(guitar_instance).not_to eq violin
    end

    it "returns false when compared with non-Stringing" do
      expect(guitar_instance).not_to eq "guitar"
    end

    it "returns false when compared with nil" do
      expect(guitar_instance).not_to be_nil
    end
  end

  describe "#to_s" do
    it "returns a descriptive string" do
      expect(described_class.for_instrument(:guitar).to_s).to eq "6-course stringing for guitar"
      expect(described_class.for_instrument(:violin).to_s).to eq "4-course stringing for violin"
    end
  end
end
