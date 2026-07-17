require "spec_helper"

describe HeadMusic::Content::Comment do
  let(:composition) { HeadMusic::Content::Composition.new(name: "Reel Thing") }

  context "when constructed with text only" do
    subject(:comment) { described_class.new(composition, "from a session in Doolin") }

    its(:composition) { is_expected.to eq composition }
    its(:text) { is_expected.to eq "from a session in Doolin" }
    its(:position) { is_expected.to be_nil }
    its(:to_s) { is_expected.to eq "from a session in Doolin" }
  end

  context "when constructed with a string position" do
    subject(:comment) { described_class.new(composition, "key change ahead", "3:1") }

    it "coerces the string to a position" do
      expect(comment.position).to be_a(HeadMusic::Content::Position)
    end

    it "anchors the position to the composition" do
      expect(comment.position.composition).to eq composition
    end

    it "places the position at the given bar and count" do
      expect(comment.position.to_s).to eq "3:1:000"
    end
  end

  context "when constructed with a position from the same composition" do
    subject(:comment) { described_class.new(composition, "the turn", position) }

    let(:position) { HeadMusic::Content::Position.new(composition, "2:1") }

    it "accepts the position as given" do
      expect(comment.position).to be position
    end
  end

  context "when constructed with a position from a different composition" do
    let(:other_composition) { HeadMusic::Content::Composition.new(name: "Other Tune") }
    let(:position) { HeadMusic::Content::Position.new(other_composition, "2:1") }

    it "raises an error" do
      expect { described_class.new(composition, "the turn", position) }.to raise_error(ArgumentError)
    end
  end

  describe "#to_h" do
    context "with a position" do
      subject(:comment) { described_class.new(composition, "the turn", "2:1") }

      it "serializes the text and position string" do
        expect(comment.to_h).to eq("text" => "the turn", "position" => "2:1:000")
      end
    end

    context "without a position" do
      subject(:comment) { described_class.new(composition, "Traditional") }

      it "serializes the position as nil" do
        expect(comment.to_h).to eq("text" => "Traditional", "position" => nil)
      end
    end
  end
end
