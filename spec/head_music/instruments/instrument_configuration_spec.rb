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
      subject(:configs) { described_class.for_instrument(:harmonica) }

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

    it "returns false when compared with non-InstrumentConfiguration" do
      expect(leadpipe_piccolo).not_to eq "some string"
    end
  end

  describe "#to_s" do
    subject { described_class.new(name_key: "leadpipe", instrument_key: "trumpet", options_data: {}) }

    its(:to_s) { is_expected.to eq "leadpipe" }
  end

  describe "trumpet mute configuration" do
    subject(:configs) { described_class.for_instrument(:trumpet) }

    it "has a mute configuration" do
      expect(configs.map(&:name_key)).to eq [:mute]
    end

    describe "mute options" do
      subject(:mute_config) { configs.first }

      it "has the expected mute options" do
        option_keys = mute_config.options.map(&:name_key)
        expect(option_keys).to contain_exactly(:open, :straight, :cup, :harmon, :bucket, :plunger)
      end

      it "defaults to open" do
        expect(mute_config.default_option.name_key).to eq :open
      end
    end
  end

  describe "bass_trombone configurations" do
    subject(:configs) { described_class.for_instrument(:bass_trombone) }

    it "has f_attachment and mute configurations" do
      expect(configs.map(&:name_key)).to contain_exactly(:f_attachment, :mute)
    end

    describe "f_attachment configuration" do
      subject(:f_attachment) { configs.find { |c| c.name_key == :f_attachment } }

      it "has disengaged and engaged options" do
        option_keys = f_attachment.options.map(&:name_key)
        expect(option_keys).to contain_exactly(:disengaged, :engaged)
      end

      it "defaults to disengaged" do
        expect(f_attachment.default_option.name_key).to eq :disengaged
      end

      it "lowers the range by 6 semitones when engaged" do
        engaged = f_attachment.option(:engaged)
        expect(engaged.lowest_pitch_semitones).to eq(-6)
      end
    end

    describe "mute configuration" do
      subject(:mute_config) { configs.find { |c| c.name_key == :mute } }

      it "has the expected mute options" do
        option_keys = mute_config.options.map(&:name_key)
        expect(option_keys).to contain_exactly(:open, :straight, :bucket)
      end
    end
  end

  describe "guitar capo configuration" do
    subject(:configs) { described_class.for_instrument(:guitar) }

    it "has a capo configuration" do
      expect(configs.map(&:name_key)).to eq [:capo]
    end

    describe "capo options" do
      subject(:capo_config) { configs.first }

      it "has fret options from none through fret_9" do
        option_keys = capo_config.options.map(&:name_key)
        expect(option_keys).to include(:none, :fret_1, :fret_5, :fret_9)
      end

      it "defaults to none" do
        expect(capo_config.default_option.name_key).to eq :none
      end

      it "transposes up by the fret number" do
        expect(capo_config.option(:fret_1).transposition_semitones).to eq 1
        expect(capo_config.option(:fret_5).transposition_semitones).to eq 5
        expect(capo_config.option(:fret_9).transposition_semitones).to eq 9
      end

      it "has no transposition for none" do
        expect(capo_config.option(:none).transposition_semitones).to be_nil
      end
    end
  end
end
