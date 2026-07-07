require "spec_helper"

describe HeadMusic::Style::Guidelines::NoteCountPerBar do
  subject(:annotation) { described_class.new(counterpoint, count: count, rhythmic_value: rhythmic_value) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }
  let(:count) { 1 }
  let(:rhythmic_value) { :whole }
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4] }

  before do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end
  end

  context "without a cantus firmus voice" do
    # The counterpoint belongs to its own composition with no other voice, so
    # there is no cantus firmus and marks short-circuits to an empty array.
    let(:solo_composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
    let(:counterpoint) { solo_composition.add_voice(role: :counterpoint) }

    it { is_expected.to be_adherent }

    it "returns no marks" do
      expect(annotation.marks).to eq []
    end
  end

  context "with two or fewer cantus firmus notes (no middle bars)" do
    let(:cantus_firmus_pitches) { %w[D4 D4] }

    it { is_expected.to be_adherent }

    it "returns no marks" do
      expect(annotation.marks).to eq []
    end
  end

  context "with the correct note in each middle bar" do
    before do
      %w[A4 A4 C5 B4 D5].each.with_index(1) do |pitch, bar|
        counterpoint.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context "with the wrong notes in a middle bar" do
    before do
      # Middle bar 2 has two half notes instead of the required single whole
      # note, so its placements are marked.
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :half, "A4")
      counterpoint.place("2:3", :half, "C5")
      counterpoint.place("3:1", :whole, "B4")
      counterpoint.place("4:1", :whole, "A4")
      counterpoint.place("5:1", :whole, "D5")
    end

    it { is_expected.not_to be_adherent }

    it "marks the offending bar" do
      expect(annotation.marks).not_to be_empty
    end
  end

  context "with an empty middle bar" do
    before do
      # Middle bars are 2, 3, 4. Place notes in bars 1, 2, 4 but leave bar 3
      # empty so the empty-bar branch marks the cantus firmus note there.
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :whole, "A4")
      counterpoint.place("4:1", :whole, "B4")
    end

    it { is_expected.not_to be_adherent }

    it "marks the empty middle bar" do
      expect(annotation.marks).not_to be_empty
    end
  end

  describe "#message" do
    context "when the count is one" do
      let(:count) { 1 }
      let(:rhythmic_value) { :whole }

      it "uses the singular noun" do
        expect(annotation.message).to eq "Use one whole note in each middle bar."
      end
    end

    context "when the count is more than one" do
      let(:count) { 2 }
      let(:rhythmic_value) { :half }

      it "uses the plural noun" do
        expect(annotation.message).to eq "Use two half notes in each middle bar."
      end
    end
  end
end
