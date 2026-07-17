require "spec_helper"

describe HeadMusic::Content::Placement do
  # rubocop:disable RSpec/MultipleMemoizedHelpers
  subject(:placement) { described_class.new(voice, position, rhythmic_value, pitch) }

  let(:composition) { HeadMusic::Content::Composition.new.tap(&:add_voice) }
  let(:voice) { composition.voices.first }
  let(:position) { "2:2:240" }
  let(:pitch) { HeadMusic::Rudiment::Pitch.get("F#4") }
  let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:eighth) }

  its(:composition) { is_expected.to eq composition }
  its(:voice) { is_expected.to eq voice }
  its(:position) { is_expected.to eq HeadMusic::Content::Position.new(composition, "2:2:240") }
  its(:pitch) { is_expected.to eq "F#4" }

  context "when pitch is omitted" do
    let(:pitch) { nil }

    it { is_expected.to be_rest }

    context "when the rhythmic value is a thirty-second note" do
      let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:"thirty-second") }

      its(:rhythmic_value) { is_expected.to eq "thirty-second" }
    end
  end

  describe "#next_position" do
    specify { expect(placement.next_position).to eq "2:2:720" }

    context "when the rhythmic value is longer than a measure" do
      let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:breve) }

      specify { expect(placement.next_position).to eq "4:2:240" }
    end

    context "when the value occurs at a fractional position" do
      let(:position) { "5:1:001" }
      let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:"thirty-second") }

      specify { expect(placement.next_position).to eq "5:1:121" }
    end
  end

  describe "#during?" do
    subject(:placement) { described_class.new(voice, position, rhythmic_value, pitch) }

    let(:other_placement) { described_class.new(voice, "2:2:000", :quarter) }

    context "when it starts before the other placement and ends at the start" do
      let(:position) { "2:1:000" }
      let(:rhythmic_value) { :quarter }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.not_to be_during(other_placement) }
    end

    context "when it starts at the same time as the other placement" do
      let(:position) { "2:2:000" }
      let(:rhythmic_value) { :eighth }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.to be_during(other_placement) }
    end

    context "when it starts during the other placement" do
      let(:position) { "2:2:480" }
      let(:rhythmic_value) { :quarter }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.to be_during(other_placement) }
    end

    context "when it starts after and ends before the other placement" do
      let(:position) { "2:2:240" }
      let(:rhythmic_value) { :sixteenth }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.to be_during(other_placement) }
    end

    context "when it starts before and ends after the other placement" do
      let(:position) { "2:1:000" }
      let(:rhythmic_value) { :whole }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:wraps?, other_placement)).to be_truthy }

      it { is_expected.to be_during(other_placement) }
    end

    context "when it ends during the other placement" do
      let(:position) { "2:1:480" }
      let(:rhythmic_value) { :quarter }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.to be_during(other_placement) }
    end

    context "when it starts at the end of the other placement" do
      let(:position) { "2:3" }
      let(:rhythmic_value) { :quarter }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.not_to be_during(other_placement) }
    end
  end

  describe "#to_h" do
    it "serializes a pitched note with string keys and values" do
      expect(placement.to_h).to eq(
        "position" => "2:2:240",
        "rhythmic_value" => "eighth",
        "pitches" => ["F♯4"]
      )
    end

    context "when the placement is a rest" do
      let(:pitch) { nil }

      it "serializes an empty pitches array" do
        expect(placement.to_h["pitches"]).to eq []
      end
    end

    context "when the position has a tick offset" do
      let(:position) { "1:1:480" }

      it "preserves the exact position string" do
        expect(placement.to_h["position"]).to eq "1:1:480"
      end
    end
  end

  describe "chords" do
    context "when given a single bare pitch" do
      it { is_expected.not_to be_chord }
      it { is_expected.to be_note }

      it "wraps the pitch in a frozen single-element pitches array" do
        expect(placement.pitches.map(&:to_s)).to eq ["F♯4"]
        expect(placement.pitches).to be_frozen
      end
    end

    context "when given an array of pitches" do
      let(:pitch) { %w[G4 C4 E4] }

      it { is_expected.to be_chord }
      it { is_expected.to be_note }
      it { is_expected.not_to be_rest }

      it "preserves the order of the given pitches" do
        expect(placement.pitches.map(&:to_s)).to eq %w[G4 C4 E4]
      end

      it "freezes the pitches array" do
        expect(placement.pitches).to be_frozen
      end

      it "derives the pitch from the highest chord tone" do
        expect(placement.pitch.to_s).to eq "G4"
      end

      it "serializes the pitches in order" do
        expect(placement.to_h).to eq(
          "position" => "2:2:240",
          "rhythmic_value" => "eighth",
          "pitches" => %w[G4 C4 E4]
        )
      end

      it "joins the pitches with spaces in to_s" do
        expect(placement.to_s).to eq "eighth G4 C4 E4 at 2:2:240"
      end
    end

    context "when chord tones tie enharmonically" do
      let(:pitch) { %w[B♭4 A♯4] }

      it "derives the first-listed pitch of the tie" do
        expect(placement.pitch.to_s).to eq "B♭4"
      end
    end

    context "when given a single-element array" do
      let(:pitch) { ["F#4"] }
      let(:bare_placement) { described_class.new(voice, position, rhythmic_value, "F#4") }

      it { is_expected.not_to be_chord }
      it { is_expected.to be_note }

      it "behaves identically to a bare pitch" do
        expect(placement.to_h).to eq bare_placement.to_h
        expect(placement.to_s).to eq bare_placement.to_s
      end
    end

    context "when given an empty array" do
      let(:pitch) { [] }

      it { is_expected.to be_rest }
      it { is_expected.not_to be_note }
      it { is_expected.not_to be_chord }

      it "serializes an empty pitches array" do
        expect(placement.to_h["pitches"]).to eq []
      end
    end

    context "when given duplicate pitches" do
      let(:pitch) { %w[C4 C4] }

      it { is_expected.not_to be_chord }

      it "keeps one of each pitch" do
        expect(placement.pitches.map(&:to_s)).to eq %w[C4]
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
