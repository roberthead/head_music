require "spec_helper"

describe HeadMusic::Style::Guidelines::IndependentTextures do
  let(:flow) do
    HeadMusic::Notation::ABC.parse(<<~ABC)
      X:1
      M:4/4
      L:1/4
      K:C
      V:upper
      #{upper}
      V:lower
      #{lower}
    ABC
  end

  def marked_bars(voice, **config)
    assess(described_class, voice, **config).marks.map { |mark| mark.start_position.bar_number }.uniq
  end

  context "with both voices in quarters for three bars" do
    let(:upper) { "e f g a|g f e d|c d e f|e4|]" }
    let(:lower) { "C D E F|G F E D|C B, A, B,|C4|]" }

    it "marks the run in each voice" do
      expect([marked_bars(flow.voices.first), marked_bars(flow.voices.last)]).to eq [[1, 2, 3], [1, 2, 3]]
    end

    it "accepts the run under a longer maximum" do
      expect(marked_bars(flow.voices.first, maximum_run: 3)).to be_empty
    end
  end

  context "with both voices in quarters for two bars" do
    let(:upper) { "e f g a|g f e d|c4|e4|]" }
    let(:lower) { "C D E F|G F E D|E4|C4|]" }

    it "marks nothing" do
      expect(marked_bars(flow.voices.first)).to be_empty
    end
  end

  context "with quarters against whole notes for many bars" do
    let(:upper) { "e f g a|g f e d|c d e f|g f e d|c4|]" }
    let(:lower) { "C4|G,4|A,4|B,4|C4|]" }

    it "marks nothing, since each voice may keep its own texture" do
      expect(marked_bars(flow.voices.first)).to be_empty
    end
  end

  context "with a different shared texture in each bar" do
    let(:upper) { "e f g a|g2 f2|e4|g f e d|c4|]" }
    let(:lower) { "C D E F|G,2 A,2|C4|G, A, B, G,|C4|]" }

    it "marks nothing" do
      expect(marked_bars(flow.voices.first)).to be_empty
    end
  end

  context "with no other voice" do
    let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nc d e f|g a b c'|d' c' b a|g4|]\n") }

    it "marks nothing" do
      expect(marked_bars(flow.voices.first)).to be_empty
    end
  end
end
