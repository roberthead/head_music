# frozen_string_literal: true

require "spec_helper"

RSpec.describe HeadMusic::Rudiment::TonalContext do
  describe "initialization" do
    it "requires a tonic spelling argument" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end
  end

  describe "required interface methods" do
    let(:concrete_class) do
      Class.new(described_class) do
        def initialize(tonic_spelling = "C")
          super
        end

        def scale
          HeadMusic::Rudiment::Scale.get(tonic_spelling, :major)
        end

        def key_signature
          HeadMusic::Rudiment::KeySignature.get("#{tonic_spelling} major")
        end
      end
    end
    let(:instance) { concrete_class.new }

    it "requires subclasses to implement #key_signature" do
      expect(instance.key_signature).to be_a(HeadMusic::Rudiment::KeySignature)
    end

    it "requires subclasses to implement #scale" do
      expect(instance.scale).to be_a(HeadMusic::Rudiment::Scale)
    end
  end

  describe "provided methods" do
    let(:concrete_class) do
      Class.new(described_class) do
        def initialize(tonic_spelling = "C")
          super
          # Store a scale with a specific starting pitch
          @scale = HeadMusic::Rudiment::Scale.get("#{tonic_spelling}4", :major)
        end

        attr_reader :scale

        def key_signature
          HeadMusic::Rudiment::KeySignature.get("#{tonic_spelling} major")
        end
      end
    end
    let(:instance) { concrete_class.new("D") }

    it "provides #tonic_spelling" do
      expect(instance.tonic_spelling.to_s).to eq("D")
    end

    it "provides #tonic_pitch with default octave" do
      expect(instance.tonic_pitch.to_s).to eq("D4")
    end

    it "provides #tonic_pitch with specified octave" do
      expect(instance.tonic_pitch(5).to_s).to eq("D5")
    end

    it "provides #pitches delegated to scale" do
      # Test without octave parameter - uses default
      expect(instance.pitches).to be_an(Array)
      expect(instance.pitches.first).to be_a(HeadMusic::Rudiment::Pitch)

      # Test with octave parameter
      pitches_with_octave = instance.pitches(5)
      expect(pitches_with_octave).to be_an(Array)
      expect(pitches_with_octave.first).to be_a(HeadMusic::Rudiment::Pitch)
    end

    it "provides #pitch_classes delegated to scale" do
      expect(instance.pitch_classes).to be_an(Array)
      expect(instance.pitch_classes.first).to be_a(HeadMusic::Rudiment::PitchClass)
    end

    it "provides #spellings delegated to scale" do
      expect(instance.spellings).to be_an(Array)
      expect(instance.spellings.first).to be_a(HeadMusic::Rudiment::Spelling)
    end
  end

  describe "abstract methods" do
    subject(:instance) { described_class.new("C") }

    it "raises an error when abstract methods are called" do
      expect { instance.scale }.to raise_error(NotImplementedError, "Subclasses must implement #scale")
      expect { instance.key_signature }.to raise_error(NotImplementedError, "Subclasses must implement #key_signature")
    end
  end
end
