require "spec_helper"

describe HeadMusic::Notation::RenderPlan do
  let(:flow) { HeadMusic::Content::Flow.new(name: "Plan", key_signature: "C major", meter: "4/4") }

  it "requires a subclass to say how its format renders a key signature" do
    expect { described_class.new(flow) }.to raise_error(NotImplementedError, /key signature/)
  end

  context "with a subclass that renders a key signature" do
    subject(:plan) { plan_class.new(flow) }

    let(:plan_class) do
      Class.new(described_class) do
        private

        def key_value(event)
          event.printed_key_signature.to_s
        end
      end
    end

    it "tracks the bars of the flow" do
      flow.add_voice.place("3:1", :whole, "C4")
      expect(plan.bar_numbers).to eq(1..3)
    end

    it "answers the flow's key signature for the first measure" do
      expect(plan.first_measure_key).to eq flow.key_signature.to_s
    end

    # The plan is handed the event, not a key signature, because MusicXML
    # renders the signature and the interpretation as separate elements while
    # LilyPond can only say one of them.
    it "hands the subclass the key signature event" do
      expect(plan.first_measure_key).to be_a String
    end

    it "renders the key signature of each bar that changes it" do
      voice = flow.add_voice
      voice.place("1:1", :whole, "C4")
      flow.change_key_signature(2, "D major")
      voice.place("2:1", :whole, "D4")
      expect(plan.measure_key_changes).to eq(2 => HeadMusic::Rudiment::KeySignature.get("D major").to_s)
    end

    it "answers the flow's meter for the first measure" do
      expect(plan.first_measure_meter).to eq HeadMusic::Rudiment::Meter.get("4/4")
    end

    it "carries a meter change forward to the bars that follow it" do
      voice = flow.add_voice
      voice.place("1:1", :whole, "C4")
      flow.change_meter(2, "3/4")
      voice.place("2:1", :half, "D4")
      expect(plan.effective_meter(3)).to eq HeadMusic::Rudiment::Meter.get("3/4")
    end

    it "groups a voice's placements by bar" do
      voice = flow.add_voice
      voice.place("1:1", :whole, "C4")
      voice.place("2:1", :whole, "D4")
      expect(plan.placements_by_bar(voice).keys).to eq [1, 2]
    end
  end
end
