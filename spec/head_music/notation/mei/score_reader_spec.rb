require "spec_helper"

describe HeadMusic::Notation::MEI::ScoreReader do
  describe described_class::Pending do
    let(:tied_class) { Struct.new(:tie_starts, :tie_stops) }
    let(:event) { tied_class.new([], []) }
    let(:grace) { tied_class.new([], []) }
    let(:sound) { HeadMusic::Rudiment::Pitch.get("C4") }

    it "starts and stops a tie on its event's sound" do
      pending = described_class.new(event: event, sound: sound)
      pending.start_tie
      pending.stop_tie
      expect([event.tie_starts, event.tie_stops]).to eq [["C4"], ["C4"]]
    end

    it "starts a grace note's tie on the grace note, and stops none" do
      pending = described_class.new(event: event, grace: grace, sound: sound)
      pending.start_tie
      pending.stop_tie
      expect([grace.tie_starts, event.tie_starts, event.tie_stops]).to eq [["C4"], [], []]
    end

    it "ties nothing where no voice placed it" do
      pending = described_class.new(sound: sound)
      expect { [pending.start_tie, pending.stop_tie] }.not_to raise_error
    end
  end
end
