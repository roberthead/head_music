require "spec_helper"

# Two layouts over one project are two documents from one body of music, and a
# layout that selects nothing away is the document the flow already rendered.
describe HeadMusic::Content::Layout do
  let(:project) { LayoutFixtures.suite }
  let(:flute) { project.players.first }
  let(:violin) { project.players.last }

  describe "two layouts over one project" do
    let(:first_movement) { [project.flows.first] }
    let(:flute_part) { project.add_layout(kind: :part, flows: first_movement, players: [flute]) }
    let(:violin_part) { project.add_layout(kind: :part, flows: first_movement, players: [violin]) }

    it "renders different ABC" do
      expect(flute_part.to_abc).not_to eq violin_part.to_abc
    end

    it "renders different LilyPond" do
      expect(flute_part.to_lilypond).not_to eq violin_part.to_lilypond
    end

    it "renders different MusicXML" do
      expect(flute_part.to_musicxml).not_to eq violin_part.to_musicxml
    end

    it "gives each part only its own notes" do
      expect(flute_part.to_abc.lines.last).to eq "c8|d8|e8|f8|]\n"
    end

    it "gives a score every player's staff and a part only one" do
      score = project.add_layout(kind: :score, flows: first_movement)
      expect([score.to_lilypond, flute_part.to_lilypond].map { |source| source.scan("\\new Staff").length })
        .to eq [2, 1]
    end

    it "lists only the selected player in the MusicXML part list" do
      document = parse_musicxml(flute_part.to_musicxml)
      expect(xpath_texts(document, "//part-list/score-part/part-name")).to eq %w[Flute]
    end
  end

  describe "a part book" do
    subject(:layout) { project.add_layout(kind: :part, players: [flute]) }

    it "renders one ABC tune per movement the player appears in" do
      expect(HeadMusic::Notation::ABC.parse_book(layout.to_abc).map(&:name)).to eq %w[I III]
    end

    it "numbers the tunes from one" do
      expect(layout.to_abc.scan(/^X:\d+$/)).to eq %w[X:1 X:2]
    end

    it "renders one LilyPond document" do
      expect(layout.to_lilypond.scan("\\version").length).to eq 1
    end

    it "renders one LilyPond score per movement" do
      expect(layout.to_lilypond.scan("\\score {").length).to eq 2
    end

    it "refuses to render several movements as one MusicXML document" do
      expect { layout.to_musicxml }
        .to raise_error HeadMusic::Notation::RenderError, /use #to_musicxml_documents/
    end

    it "renders one MusicXML document per movement" do
      expect(layout.to_musicxml_documents.length).to eq 2
    end

    it "renders a MusicXML document that parses" do
      document = parse_musicxml(layout.to_musicxml_documents.last)
      expect(xpath_text(document, "//movement-title")).to eq "III"
    end
  end

  describe "a layout that renders nothing" do
    subject(:layout) { project.add_layout(kind: :part, flows: [project.flows[1]], players: [flute]) }

    it "refuses to render ABC" do
      expect { layout.to_abc }.to raise_error HeadMusic::Notation::RenderError, /selects no flow/
    end

    it "refuses to render LilyPond" do
      expect { layout.to_lilypond }.to raise_error HeadMusic::Notation::RenderError, /selects no flow/
    end

    it "refuses to render MusicXML" do
      expect { layout.to_musicxml }.to raise_error HeadMusic::Notation::RenderError, /selects no flow/
    end
  end

  # The guard on every existing document: selecting nothing away must produce
  # the bytes the flow produced before layouts existed.
  describe "a layout that selects nothing away" do
    let(:project) { LayoutFixtures.single_flow_project }
    let(:flow) { project.flows.first }
    let(:layout) { project.add_layout }

    it "renders the flow's own ABC" do
      expect(layout.to_abc).to eq flow.to_abc
    end

    it "renders the flow's own LilyPond" do
      expect(layout.to_lilypond).to eq flow.to_lilypond
    end

    it "renders the flow's own MusicXML" do
      expect(layout.to_musicxml).to eq flow.to_musicxml
    end
  end
end
