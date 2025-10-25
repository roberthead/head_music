require "spec_helper"

describe HeadMusic::Time::TempoEvent do
  describe "#initialize" do
    subject(:event) { described_class.new(position, beat_value, beats_per_minute) }

    let(:position) { HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0) }
    let(:beat_value) { "quarter" }
    let(:beats_per_minute) { 120 }

    its(:position) { is_expected.to eq position }

    it "creates a tempo from beat_value and beats_per_minute" do
      expect(event.tempo).to be_a(HeadMusic::Rudiment::Tempo)
      expect(event.tempo.beat_value.to_s).to eq "quarter"
      expect(event.tempo.beats_per_minute).to eq 120.0
    end

    context "with different tempo" do
      let(:beat_value) { "eighth" }
      let(:beats_per_minute) { 140 }

      it "creates the correct tempo" do
        expect(event.tempo.beat_value.to_s).to eq "eighth"
        expect(event.tempo.beats_per_minute).to eq 140.0
      end
    end

    context "with different position" do
      let(:position) { HeadMusic::Time::MusicalPosition.new(10, 1, 0, 0) }

      its(:position) { is_expected.to eq position }
    end

    context "with dotted note value" do
      let(:beat_value) { "dotted quarter" }
      let(:beats_per_minute) { 92 }

      it "creates tempo with dotted note" do
        expect(event.tempo.beat_value.to_s).to eq "dotted quarter"
        expect(event.tempo.beats_per_minute).to eq 92.0
      end
    end

    context "with integer beats_per_minute" do
      let(:beats_per_minute) { 100 }

      it "converts to float in tempo" do
        expect(event.tempo.beats_per_minute).to eq 100.0
        expect(event.tempo.beats_per_minute).to be_a(Float)
      end
    end
  end

  describe "position modification" do
    subject(:event) { described_class.new(position, "quarter", 120) }

    let(:position) { HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0) }

    it "allows position to be updated" do
      new_position = HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0)
      event.position = new_position
      expect(event.position).to eq new_position
    end
  end

  describe "tempo modification" do
    subject(:event) { described_class.new(position, "quarter", 120) }

    let(:position) { HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0) }

    it "allows tempo to be updated" do
      new_tempo = HeadMusic::Rudiment::Tempo.new("half", 80)
      event.tempo = new_tempo
      expect(event.tempo).to eq new_tempo
    end
  end

  describe "tempo access" do
    subject(:event) { described_class.new(position, "quarter", 120) }

    let(:position) { HeadMusic::Time::MusicalPosition.new(1, 1, 0, 0) }

    it "provides access to tempo properties" do
      expect(event.tempo.beat_duration_in_seconds).to eq 0.5
      expect(event.tempo.beat_duration_in_nanoseconds).to eq 500_000_000
    end
  end
end
