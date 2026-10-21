require "spec_helper"

describe TimelineExpressionFixtures do
  def spans(items)
    items.map { |item| [item.from.to_s, item.to.to_s] }
  end

  describe ".melody" do
    subject(:flow) { described_class.melody }

    it "is in common time" do
      expect(flow.meter.symbol).to eq :common
    end

    it "opens with tempo text and changes to another in bar 3" do
      expect([flow.tempo_at(1), flow.tempo_changes]).to eq [
        HeadMusic::Rudiment::Tempo.new("quarter", 120, text: "Allegro"),
        {3 => HeadMusic::Rudiment::Tempo.new("quarter", 96, text: "Meno mosso")}
      ]
    end

    it "holds a rit. to a written target and an accel. ending at a fermata" do
      expect(flow.tempo_ramps.map { |ramp| [ramp.from.to_s, ramp.to.to_s, ramp.to_tempo&.beats_per_minute, ramp.text] })
        .to eq [["3:3:000", "4:1:000", 72.0, "rit."], ["5:3:000", "6:3:000", nil, "accel."]]
    end

    it "restores the tempo with an \"a tempo\" in the middle of bar 4" do
      expect([flow.a_tempos.map { |a_tempo| a_tempo.position.to_s }, flow.tempo_at(5).beats_per_minute]).to eq [["4:3:000"], 96.0]
    end

    it "holds a fermata on a note and one on a rest" do
      expect(spans(flow.fermatas)).to eq [["2:3:000", "3:1:000"], ["6:3:000", "7:1:000"]]
    end
  end

  describe ".chorale" do
    subject(:flow) { described_class.chorale }

    it "is two voices in cut time, at a half note to 60" do
      expect([flow.voices.length, flow.meter.symbol, flow.tempo_at(1)]).to eq [2, :cut, HeadMusic::Rudiment::Tempo.new("half", 60)]
    end

    it "holds a fermata from the second of the bass eighths to the end of the soprano quarter, and one at the end" do
      expect(spans(flow.fermatas)).to eq [["2:1:1440", "2:2:000"], ["4:2:000", "5:1:000"]]
    end

    it "holds a rit. ending at the final fermata, with no written target" do
      expect(flow.tempo_ramps.map { |ramp| [ramp.from.to_s, ramp.to.to_s, ramp.to_tempo, ramp.text] }).to eq [["3:2:000", "4:2:000", nil, "rit."]]
    end
  end

  describe "expect_same_timeline" do
    let(:original) { described_class.melody }
    let(:changed) do
      described_class.melody.tap do |flow|
        flow.remove_fermata("2:3")
        flow.add_fermata("2:3", :half, stretch: 3)
      end
    end

    it "compares the fermatas' stretch" do
      expect(described_class.timeline(changed)).not_to eq described_class.timeline(original)
    end

    it "leaves out what it is told to" do
      expect_same_timeline(original, changed, except: [:stretch])
    end

    context "with a ramp's target written as a tempo change at its end" do
      let(:written_as_change) do
        described_class.melody.tap do |flow|
          flow.remove_tempo_ramp("3:3")
          flow.add_tempo_ramp(from: "3:3", to: "4:1", text: "rit.")
          flow.change_tempo(4, HeadMusic::Rudiment::Tempo.new("quarter", 72))
        end
      end

      it "compares the target as resolved" do
        expect_same_timeline(original, written_as_change)
      end
    end

    it "compares tempos as quarter notes per minute when told to leave out beat values" do
      expect(described_class.timeline(described_class.chorale, except: [:beat_values])[:tempos].first).to eq [120.0, nil, true]
    end

    it "raises for an omission it does not know" do
      expect { described_class.timeline(original, except: [:stretches]) }.to raise_error(ArgumentError, /stretches/)
    end
  end

  describe ".tied_under_two_fermatas" do
    subject(:flow) { described_class.tied_under_two_fermatas }

    it "holds the alto's tied note under both fermatas" do
      alto = flow.voices.first.voice_events.map(&:to_s)
      expect([alto, spans(flow.fermatas)]).to eq [
        ["half C4 at 1:1:000", "half tied to half E4 at 1:3:000", "half F4 at 2:3:000"],
        [["1:3:000", "2:1:000"], ["2:1:000", "2:3:000"]]
      ]
    end

    it "writes the alto alone for one voice" do
      expect(described_class.tied_under_two_fermatas(voices: 1).voices.length).to eq 1
    end
  end
end
