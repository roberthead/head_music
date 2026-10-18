require "spec_helper"

describe HeadMusic::Content::Voice::SpanAnchors do
  subject(:anchors) { described_class.new(voice) }

  let(:flow) { HeadMusic::Content::Flow.new }
  let(:voice) { flow.add_voice }

  def span(kind, from, to, from_grace: false)
    HeadMusic::Content::Span.new(flow, kind, from: from, to: to, from_grace: from_grace)
  end

  before do
    voice.place("1:1", :quarter, "C4")
    voice.place("1:2", :quarter)
    voice.place("1:3", :half, "E4")
  end

  describe "#ensure_anchored" do
    it "accepts a slur from one note to another" do
      expect { anchors.ensure_anchored(span(:slur, "1:1", "1:3")) }.not_to raise_error
    end

    it "refuses a slur that ends on a rest" do
      expect { anchors.ensure_anchored(span(:slur, "1:1", "1:2")) }
        .to raise_error(ArgumentError, /must start and end on .* of its voice, but 1:2:000 has none/)
    end

    it "refuses a slur from grace notes the note does not have" do
      expect { anchors.ensure_anchored(span(:slur, "1:1", "1:3", from_grace: true)) }
        .to raise_error(ArgumentError, "a slur from grace notes needs a note with grace notes at 1:1:000")
    end
  end

  describe "#end_of" do
    it "runs a slur until its last note ends" do
      expect(anchors.end_of(span(:slur, "1:1", "1:3")).to_s).to eq "2:1:000"
    end
  end
end
