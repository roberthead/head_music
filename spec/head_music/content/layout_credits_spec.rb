require "spec_helper"

describe HeadMusic::Content::Layout do
  let(:project) { LayoutFixtures.suite }
  let(:flow) { project.flows.first }

  context "when the project credits an arranger" do
    before { project.add_credit("Andrés Segovia", :arranger) }

    it "credits the arranger in a LilyPond header" do
      expect(project.add_layout(flows: [flow]).to_lilypond).to include(%(arranger = "Andrés Segovia"))
    end

    it "credits the arranger in a LilyPond book" do
      expect(project.add_layout.to_lilypond).to include(%(arranger = "Andrés Segovia"))
    end

    it "credits the arranger in MusicXML" do
      expect(project.add_layout(flows: [flow]).to_musicxml).to include(%(<creator type="arranger">Andrés Segovia</creator>))
    end

    it "leaves the flow's own output uncredited" do
      expect(flow.to_lilypond).not_to include("arranger")
      expect(flow.to_musicxml).not_to include("arranger")
    end

    it "joins two arrangers as the composer is joined" do
      project.add_credit("Julian Bream", :arranger)
      expect(project.add_layout(flows: [flow]).to_lilypond).to include(%(arranger = "Andrés Segovia, Julian Bream"))
    end
  end

  context "when the project credits no arranger" do
    it "prints no arranger line" do
      expect(project.add_layout(flows: [flow]).to_lilypond).not_to include("arranger")
      expect(project.add_layout(flows: [flow]).to_musicxml).not_to include("arranger")
    end
  end

  describe "the writers' arranger option" do
    it "is emitted by LilyPond when given" do
      expect(HeadMusic::Notation::LilyPond.render(flow, arranger: "X")).to include(%(arranger = "X"))
    end

    it "is emitted by MusicXML when given, after the composer" do
      document = HeadMusic::Notation::MusicXML.render(flow, arranger: "X")
      expect(document).to include(%(<creator type="arranger">X</creator>))
      expect(document.index("<encoding>")).to be > document.index(%(type="arranger"))
    end
  end
end
