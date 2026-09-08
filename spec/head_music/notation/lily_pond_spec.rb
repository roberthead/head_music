require "spec_helper"

describe HeadMusic::Notation::LilyPond do
  describe ".render" do
    let(:flow) do
      flow = HeadMusic::Content::Flow.new(name: "Air")
      flow.add_voice.place("1:1", :whole, "C4")
      flow
    end

    it "renders a LilyPond source string" do
      expect(described_class.render(flow)).to start_with %(\\version "2.24.0"\n)
    end

    it "rejects options until the renderer defines some" do
      expect { described_class.render(flow, transpose: 1) }.to raise_error(ArgumentError)
    end
  end

  describe "the composer header" do
    def flow_with(**attributes)
      HeadMusic::Content::Flow.new(name: "Prelude", **attributes).tap do |flow|
        flow.add_voice.place("1:1", :whole, "C4")
      end
    end

    let(:bach) do
      HeadMusic::Content::Work.new(
        title: "Cello Suite No. 1",
        catalog_number: "BWV 1007",
        credits: [HeadMusic::Content::Credit.new(person: "Johann Sebastian Bach", role: :composer)]
      )
    end

    it "carries the cited work's composer" do
      expect(described_class.render(flow_with(composer: "Bach", work: bach)))
        .to include %(composer = "Johann Sebastian Bach")
    end

    it "leaves a legacy composer string untouched" do
      expect(described_class.render(flow_with(composer: "Trad."))).to include %(composer = "Trad.")
    end
  end

  describe "RenderError" do
    it "subclasses the shared notation render error" do
      expect(described_class::RenderError.superclass).to eq HeadMusic::Notation::RenderError
    end
  end
end
