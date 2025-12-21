require "spec_helper"

describe HeadMusic::Instruments::InstrumentConfiguration do
  describe ".for_instrument" do
    context "when instrument has configurations" do
      subject(:configs) { described_class.for_instrument(:piccolo_trumpet) }

      it "returns an array of configurations" do
        expect(configs).to be_an Array
        expect(configs.length).to eq 1
      end

      it "returns InstrumentConfiguration instances" do
        expect(configs.first).to be_a described_class
      end

      it "sets the correct name_key" do
        expect(configs.first.name_key).to eq :leadpipe
      end

      it "sets the correct instrument_key" do
        expect(configs.first.instrument_key).to eq :piccolo_trumpet
      end
    end

    context "when instrument has no configurations" do
      subject(:configs) { described_class.for_instrument(:violin) }

      it { is_expected.to eq [] }
    end

    context "when instrument key does not exist" do
      subject(:configs) { described_class.for_instrument(:nonexistent) }

      it { is_expected.to eq [] }
    end
  end

  describe "#options" do
    subject(:config) { described_class.for_instrument(:piccolo_trumpet).first }

    it "returns an array of options" do
      expect(config.options).to be_an Array
      expect(config.options.length).to eq 2
    end

    it "returns InstrumentConfigurationOption instances" do
      expect(config.options).to all be_a HeadMusic::Instruments::InstrumentConfigurationOption
    end

    it "includes the expected options" do
      option_keys = config.options.map(&:name_key)
      expect(option_keys).to contain_exactly(:b_flat, :a)
    end
  end

  describe "#default_option" do
    context "when an option is marked as default" do
      subject(:config) { described_class.for_instrument(:piccolo_trumpet).first }

      it "returns the default option" do
        expect(config.default_option.name_key).to eq :b_flat
      end
    end

    context "when no option is marked as default" do
      subject(:config) do
        described_class.new(
          name_key: "test",
          instrument_key: "test",
          options_data: {"first" => {}, "second" => {}}
        )
      end

      it "returns the first option" do
        expect(config.default_option.name_key).to eq :first
      end
    end
  end

  describe "#option" do
    subject(:config) { described_class.for_instrument(:piccolo_trumpet).first }

    it "returns the option by key" do
      expect(config.option(:a)).to be_a HeadMusic::Instruments::InstrumentConfigurationOption
      expect(config.option(:a).name_key).to eq :a
    end

    it "returns nil for unknown option" do
      expect(config.option(:unknown)).to be_nil
    end
  end

  describe "option attributes" do
    context "for a leadpipe configuration" do
      subject(:config) { described_class.for_instrument(:piccolo_trumpet).first }

      it "has the correct transposition for A leadpipe" do
        a_option = config.option(:a)
        expect(a_option.transposition_semitones).to eq(-1)
      end

      it "has no transposition for B-flat leadpipe" do
        b_flat_option = config.option(:b_flat)
        expect(b_flat_option.transposition_semitones).to be_nil
      end
    end

    context "for an f_attachment configuration" do
      subject(:config) { described_class.for_instrument(:bass_trombone).first }

      it "has the correct lowest_pitch_semitones when engaged" do
        engaged_option = config.option(:engaged)
        expect(engaged_option.lowest_pitch_semitones).to eq(-6)
      end
    end
  end

  describe "#==" do
    let(:leadpipe_piccolo) { described_class.new(name_key: "leadpipe", instrument_key: "piccolo_trumpet", options_data: {}) }
    let(:leadpipe_piccolo_copy) { described_class.new(name_key: "leadpipe", instrument_key: "piccolo_trumpet", options_data: {}) }
    let(:mute_piccolo) { described_class.new(name_key: "mute", instrument_key: "piccolo_trumpet", options_data: {}) }
    let(:leadpipe_trumpet) { described_class.new(name_key: "leadpipe", instrument_key: "trumpet", options_data: {}) }

    it "compares by name_key and instrument_key" do
      expect(leadpipe_piccolo).to eq leadpipe_piccolo_copy
      expect(leadpipe_piccolo).not_to eq mute_piccolo
      expect(leadpipe_piccolo).not_to eq leadpipe_trumpet
    end
  end

  describe "#to_s" do
    subject { described_class.new(name_key: "leadpipe", instrument_key: "trumpet", options_data: {}) }

    its(:to_s) { is_expected.to eq "leadpipe" }
  end
end
