require "spec_helper"

describe HeadMusic::Analysis::HarmonicInterval do # rubocop:disable RSpec/MultipleMemoizedHelpers
  subject(:harmonic_interval) { described_class.new(high_voice, low_voice, position) }

  let(:composition) { HeadMusic::Content::Composition.new }
  let!(:high_voice) { composition.add_voice(role: :melody) }
  let!(:low_voice) { composition.add_voice(role: :bass_line) }
  let(:position) { HeadMusic::Content::Position.new(composition, "2:1") }
  let!(:high_note) { high_voice.place(position, :quarter, "D4") }
  let!(:low_note) { low_voice.place(position, :whole, "F3") }

  its(:position) { is_expected.to eq "2:1" }

  it "assigns the voices" do
    expect(harmonic_interval.voices).to match([high_voice, low_voice])
  end

  it "assigns the notes, lowest to highest" do
    expect(harmonic_interval.notes).to eq([low_note, high_note])
  end

  its(:pitches) { are_expected.to eq(%w[F3 D4]) }
  its(:upper_pitch) { is_expected.to eq "D4" }
  its(:lower_pitch) { is_expected.to eq "F3" }

  its(:diatonic_interval) { is_expected.to eq "major sixth" }

  its(:to_s) { is_expected.to eq "major sixth at 2:1:000" }

  describe "#pitch_orientation" do
    it "is :down when the lower note belongs to the second voice" do
      expect(harmonic_interval.pitch_orientation).to eq(:down)
    end

    it "is nil when the lower note belongs to neither compared voice" do
      other_voice = composition.add_voice(role: :inner)
      foreign_note = HeadMusic::Content::Note.new("F3", :whole, other_voice, position)
      allow(harmonic_interval).to receive(:lower_note).and_return(foreign_note) # rubocop:disable RSpec/SubjectStub
      expect(harmonic_interval.pitch_orientation).to be_nil
    end
  end

  describe "delegation to the diatonic interval" do
    it "raises NoMethodError for a method the diatonic interval does not answer" do
      expect { harmonic_interval.definitely_not_a_method }.to raise_error(NoMethodError)
    end
  end
end
