require "spec_helper"

describe HeadMusic::Content::Voice do
  subject(:voice) { flow.voices.first }

  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nM:4/4\nK:C\nC D E F|G A z2|c4-|c2 d2|\n") }

  def summary(spans)
    spans.map(&:to_s)
  end

  describe "#add_span" do
    it "adds a slur between two notes" do
      voice.add_span(:slur, from: "1:1", to: "1:3")
      expect(summary(voice.spans)).to eq ["slur from 1:1:000 to 1:3:000"]
    end

    it "keeps a slur nested in a phrase" do
      voice.add_span(:phrase, from: "1:1", to: "2:2")
      voice.add_span(:slur, from: "1:2", to: "1:4")
      expect(voice.spans.map(&:kind)).to eq %i[phrase slur]
    end

    it "keeps a slur that crosses a phrase" do
      voice.add_span(:phrase, from: "1:1", to: "1:3")
      voice.add_span(:slur, from: "1:2", to: "2:1")
      expect(voice.spans.length).to eq 2
    end

    it "keeps two slurs that overlap" do
      voice.add_span(:slur, from: "1:1", to: "1:3")
      voice.add_span(:slur, from: "1:2", to: "1:4")
      expect(voice.spans.length).to eq 2
    end

    it "keeps two slurs that share an end" do
      voice.add_span(:slur, from: "1:1", to: "1:3")
      voice.add_span(:slur, from: "1:3", to: "2:1")
      expect(voice.spans.length).to eq 2
    end

    it "refuses the same slur twice" do
      voice.add_span(:slur, from: "1:1", to: "1:3")
      expect { voice.add_span(:slur, from: "1:1", to: "1:3") }.to raise_error(ArgumentError, /already there/)
    end

    it "refuses a slur that ends on a rest" do
      expect { voice.add_span(:slur, from: "2:1", to: "2:3") }
        .to raise_error(ArgumentError, "a slur must start and end on a note of its voice, but 2:3:000 has none")
    end

    it "refuses a slur that starts where no voice event begins" do
      expect { voice.add_span(:slur, from: "1:1:480", to: "1:3") }.to raise_error(ArgumentError, /1:1:480 has none/)
    end

    it "lets a phrase end on a rest" do
      voice.add_span(:phrase, from: "1:1", to: "2:3")
      expect(summary(voice.spans)).to eq ["phrase from 1:1:000 to 2:3:000"]
    end

    it "refuses a phrase that ends where no voice event begins" do
      expect { voice.add_span(:phrase, from: "1:1", to: "2:4") }
        .to raise_error(ArgumentError, "a phrase must start and end on a note or rest of its voice, but 2:4:000 has none")
    end

    it "slurs across a barline to a note tied into the next bar" do
      voice.add_span(:slur, from: "2:1", to: "3:1")
      expect(voice.spans_at("4:2").map(&:kind)).to eq [:slur]
    end
  end

  describe "placing onto a spanned voice event" do
    it "keeps a slur on a note that a chord tone joins" do
      voice.add_span(:slur, from: "1:1", to: "1:3")
      voice.place("1:3", :quarter, "G4")
      expect([summary(voice.spans), voice.voice_events[2].pitches.map(&:to_s)])
        .to eq [["slur from 1:1:000 to 1:3:000"], %w[E4 G4]]
    end

    it "keeps a slur on a note that a rest is placed on" do
      voice.add_span(:slur, from: "1:1", to: "1:3")
      voice.place("1:3", :quarter)
      expect([summary(voice.spans), voice.voice_events[2].rest?]).to eq [["slur from 1:1:000 to 1:3:000"], false]
    end

    it "keeps a phrase ending on a rest that a note replaces" do
      voice.add_span(:phrase, from: "1:1", to: "2:3")
      voice.place("2:3", :half, "B4")
      expect(voice.spans_at("2:4").map(&:kind)).to eq [:phrase]
    end
  end

  describe "#spans_at" do
    before do
      voice.add_span(:phrase, from: "1:1", to: "2:2")
      voice.add_span(:slur, from: "1:2", to: "1:3")
    end

    it "answers the innermost span first" do
      expect(voice.spans_at("1:2").map(&:kind)).to eq %i[slur phrase]
    end

    it "covers the whole of a slur's last note" do
      expect(voice.spans_at("1:3:480").map(&:kind)).to eq %i[slur phrase]
    end

    it "ends a slur where its last note ends" do
      expect(voice.spans_at("1:4").map(&:kind)).to eq [:phrase]
    end

    it "answers nothing before the first span or after the last" do
      expect([voice.spans_at("2:3"), voice.spans_at("0:1")]).to all(be_empty)
    end
  end

  describe "across a staff crossing" do
    let(:flow) { LilyPondFixtures.cross_staff_piano }

    it "slurs the crossing hand from one staff to the other" do
      left_hand = flow.voices.last
      left_hand.add_span(:slur, from: "1:1", to: "2:1")
      expect([left_hand.staff_at(1), left_hand.staff_at(2)].uniq.length).to eq 2
    end
  end

  describe "#to_h" do
    it "writes its spans" do
      voice.add_span(:slur, from: "1:1", to: "1:3")
      expect(voice.to_h["spans"]).to eq [{"kind" => "slur", "from" => "1:1:000", "to" => "1:3:000"}]
    end

    it "writes no spans key without spans" do
      expect(voice.to_h).not_to have_key("spans")
    end
  end
end
