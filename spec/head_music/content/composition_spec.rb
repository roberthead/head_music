require "spec_helper"

describe HeadMusic::Content::Composition do
  subject(:composition) { described_class.new(name: "Fruit Salad") }

  its(:name) { is_expected.to eq "Fruit Salad" }

  it "defaults to the key of C major" do
    expect(composition.key_signature).to eq "C major"
  end

  it "defaults to 4/4" do
    expect(composition.meter).to eq "4/4"
  end

  its(:latest_bar_number) { is_expected.to eq 1 }
  its(:to_s) { is_expected.to eq "Fruit Salad — 0 voices" }

  its(:composer) { is_expected.to be_nil }
  its(:origin) { is_expected.to be_nil }
  its(:comments) { is_expected.to eq [] }

  context "when constructed with composer and origin" do
    subject(:composition) { described_class.new(name: "The Banshee", composer: "Traditional", origin: "Ireland") }

    its(:composer) { is_expected.to eq "Traditional" }
    its(:origin) { is_expected.to eq "Ireland" }
  end

  context "when constructed with a single comment string" do
    subject(:composition) { described_class.new(name: "The Banshee", comments: "collected in Clare") }

    it "coerces the string to one comment" do
      expect(composition.comments.map(&:to_s)).to eq ["collected in Clare"]
    end

    it "anchors the comment to the composition" do
      expect(composition.comments.first.composition).to eq composition
    end

    it "leaves the comment unpositioned" do
      expect(composition.comments.first.position).to be_nil
    end
  end

  context "when constructed with an array of comment strings" do
    subject(:composition) { described_class.new(name: "The Banshee", comments: ["collected in Clare", "also known as McMahon's"]) }

    it "coerces each string to a comment" do
      expect(composition.comments.map(&:to_s)).to eq ["collected in Clare", "also known as McMahon's"]
    end

    it "builds unpositioned comments" do
      expect(composition.comments.map(&:position)).to all(be_nil)
    end
  end

  describe "#add_comment" do
    context "without a position" do
      it "returns an unpositioned comment" do
        comment = composition.add_comment("play twice")
        expect(comment.position).to be_nil
      end

      it "appends the comment to the collection" do
        comment = composition.add_comment("play twice")
        expect(composition.comments).to include(comment)
      end
    end

    context "with a position" do
      it "anchors the comment at that position" do
        comment = composition.add_comment("the turn", "2:1")
        expect(comment.position.to_s).to eq "2:1:000"
      end
    end
  end

  context "with some placements" do
    let(:voice) { composition.add_voice(role: "melody") }

    before do
      voice.place("0:4", "quarter", "C4")
      voice.place("1:1", :eighth, "C4")
      voice.place("1:1:480", :eighth, "E4")
      voice.place("1:4", :eighth, "A3")
      voice.place("1:4:480", :eighth, "G3")
      voice.place("2:1", :eighth, "A3")
      voice.place("2:1:480", :eighth, "C4")
    end

    its(:latest_bar_number) { is_expected.to eq 2 }
    its(:to_s) { is_expected.to eq "Fruit Salad — 1 voice" }
  end

  context "when the meter changes" do
    before do
      composition.change_meter(9, "6/8")
    end

    it "starts in the original meter" do
      expect(composition.meter_at(1)).to eq "4/4"
    end

    it "remains in the original meter before the change" do
      expect(composition.meter_at(8)).to eq "4/4"
    end

    it "switches to the new meter at the change" do
      expect(composition.meter_at(9)).to eq "6/8"
    end

    it "continues on with the new meter after the change" do
      expect(composition.meter_at(15)).to eq "6/8"
    end
  end

  describe "#to_abc" do
    it "renders an ABC tune string" do
      expect(composition.to_abc).to start_with "X:1\nT:Fruit Salad\n"
    end

    it "passes options through to the renderer" do
      expect(composition.to_abc(reference_number: 12)).to start_with "X:12\n"
    end

    it "propagates render errors" do
      composition.add_voice
      composition.add_voice
      expect { composition.to_abc }.to raise_error(HeadMusic::Notation::ABC::RenderError)
    end
  end

  context "when the key signature changes" do
    before do
      composition.change_key_signature(9, "G major")
    end

    it "starts in the original key signature" do
      expect(composition.key_signature_at(1)).to eq "C major"
    end

    it "remains in the original key signature before the change" do
      expect(composition.key_signature_at(8)).to eq "C major"
    end

    it "switches to the new key signature at the change" do
      expect(composition.key_signature_at(9)).to eq "G major"
    end

    it "continues on with the new key signature after the change" do
      expect(composition.key_signature_at(15)).to eq "G major"
    end
  end
end
