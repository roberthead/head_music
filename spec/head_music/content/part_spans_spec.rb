require "spec_helper"

describe HeadMusic::Content::Part do
  subject(:part) { flow.parts.first }

  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nM:4/4\nK:C\nC4|D4|E4|F4|\n") }

  describe "#add_span" do
    it "holds a hairpin with ends anywhere" do
      part.add_span(:crescendo, from: "1:2:240", to: "3:1")
      expect(part.spans.map(&:to_s)).to eq ["crescendo from 1:2:240 to 3:1:000"]
    end

    it "refuses a slur" do
      expect { part.add_span(:slur, from: "1:1", to: "2:1") }.to raise_error(ArgumentError, "a part cannot hold a slur")
    end

    it "refuses hairpins that overlap" do
      part.add_span(:crescendo, from: "1:1", to: "2:1")
      expect { part.add_span(:diminuendo, from: "1:3", to: "2:3") }.to raise_error(ArgumentError, /overlaps/)
    end

    it "keeps hairpins that overlap in two of its voices" do
      lower = part.add_voice.tap { |voice| voice.place("1:1", :whole, "C3") }
      part.voices.first.add_span(:crescendo, from: "1:1", to: "2:1")
      lower.add_span(:diminuendo, from: "1:3", to: "2:3")
      expect(part.voices.map { |voice| voice.spans.length }).to eq [1, 1]
    end
  end

  describe "#spans_at" do
    before do
      part.add_span(:crescendo, from: "1:1", to: "2:1")
      part.add_span(:diminuendo, from: "2:1", to: "3:1")
    end

    it "answers the hairpin in force" do
      expect(part.spans_at("1:3").map(&:kind)).to eq [:crescendo]
    end

    it "answers only the diminuendo where the crescendo ends and it begins" do
      expect(part.spans_at("2:1").map(&:kind)).to eq [:diminuendo]
    end

    it "answers its hairpins to each of its voices" do
      expect(part.voices.first.spans_at("2:2").map(&:kind)).to eq [:diminuendo]
    end
  end

  context "with a hairpin past the last bar" do
    before { part.add_span(:crescendo, from: "3:1", to: "5:1") }

    it "adds no bar to the music" do
      expect([flow.latest_bar_number, flow.last_sounding_bar_number]).to eq [4, 4]
    end

    it "ends at the final barline" do
      expect(flow.final_barline_position.to_s).to eq "5:1:000"
    end
  end
end
