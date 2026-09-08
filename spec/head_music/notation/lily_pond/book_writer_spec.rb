require "spec_helper"

describe HeadMusic::Notation::LilyPond::BookWriter do
  subject(:rendered) { described_class.new(flows, title: "Session Set").to_s }

  let(:flows) { [LilyPondFixtures.speed_the_plough, LilyPondFixtures.chromatic_air] }

  describe "#to_s" do
    it "declares the version once" do
      expect(rendered.scan("\\version").length).to eq 1
    end

    it "carries one header for the whole book" do
      expect(rendered.scan("\\header {").length).to eq 3
    end

    it "titles the book" do
      expect(rendered).to include %(title = "Session Set")
    end

    it "writes one score per flow" do
      expect(rendered.scan("\\score {").length).to eq 2
    end

    it "names each movement with its own piece header" do
      expect(rendered.scan(/piece = "([^"]+)"/).flatten).to eq ["Speed the Plough", "Chromatic Air"]
    end

    it "renders the music of both flows, in order" do
      expect(bar_check_lines(rendered))
        .to eq flows.flat_map { |flow| bar_check_lines(flow.to_lilypond) }
    end

    it "ends with a newline" do
      expect(rendered).to end_with "\n"
    end

    it "balances its braces" do
      expect(rendered.count("{")).to eq rendered.count("}")
    end
  end

  describe "the book's composer" do
    it "credits the one composer every movement names" do
      book = described_class.new([LilyPondFixtures.chromatic_air, LilyPondFixtures.chromatic_air]).to_s
      expect(book).to include %(composer = "Trad.")
    end

    it "stays silent when the movements name different composers" do
      expect(rendered).not_to include "composer ="
    end
  end

  describe "the book's title" do
    it "is omitted when none was given" do
      expect(described_class.new(flows).to_s).not_to include "title ="
    end
  end

  it "refuses to write a book of no flows" do
    expect { described_class.new([]) }
      .to raise_error HeadMusic::Notation::LilyPond::RenderError, /at least one flow/
  end
end
