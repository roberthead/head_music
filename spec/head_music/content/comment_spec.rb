require "spec_helper"

describe HeadMusic::Content::Comment do
  let(:flow) { HeadMusic::Content::Flow.new(name: "Reel Thing") }

  context "when constructed with text only" do
    subject(:comment) { described_class.new(flow, "from a session in Doolin") }

    its(:flow) { is_expected.to eq flow }
    its(:text) { is_expected.to eq "from a session in Doolin" }
    its(:position) { is_expected.to be_nil }
    its(:to_s) { is_expected.to eq "from a session in Doolin" }
  end

  context "when constructed with a string position" do
    subject(:comment) { described_class.new(flow, "key change ahead", "3:1") }

    it "coerces the string to a position" do
      expect(comment.position).to be_a(HeadMusic::Content::Position)
    end

    it "anchors the position to the flow" do
      expect(comment.position.flow).to eq flow
    end

    it "places the position at the given bar and count" do
      expect(comment.position.to_s).to eq "3:1:000"
    end
  end

  context "when constructed with a position from the same flow" do
    subject(:comment) { described_class.new(flow, "the turn", position) }

    let(:position) { HeadMusic::Content::Position.new(flow, "2:1") }

    it "accepts the position as given" do
      expect(comment.position).to be position
    end
  end

  context "when constructed with a position from a different flow" do
    let(:other_flow) { HeadMusic::Content::Flow.new(name: "Other Tune") }
    let(:position) { HeadMusic::Content::Position.new(other_flow, "2:1") }

    it "raises an error" do
      expect { described_class.new(flow, "the turn", position) }.to raise_error(ArgumentError)
    end
  end

  describe "#to_h" do
    context "with a position" do
      subject(:comment) { described_class.new(flow, "the turn", "2:1") }

      it "serializes the text and position string" do
        expect(comment.to_h).to eq("text" => "the turn", "position" => "2:1:000")
      end
    end

    context "without a position" do
      subject(:comment) { described_class.new(flow, "Traditional") }

      it "serializes the position as nil" do
        expect(comment.to_h).to eq("text" => "Traditional", "position" => nil)
      end
    end
  end
end
