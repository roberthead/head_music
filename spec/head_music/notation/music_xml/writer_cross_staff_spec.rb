require "spec_helper"

# MusicXML writes a part's staves with <staves> and puts each note on one with
# <staff>, and its simultaneous voices with <voice> separated by <backup>. A
# voice that crosses staves is the same voice reporting a different <staff> on
# either side of the crossing.
describe HeadMusic::Notation::MusicXML::Writer do
  subject(:document) { parse_musicxml(described_class.new(flow).to_s) }

  let(:flow) { LilyPondFixtures.cross_staff_piano }

  it "renders the piano as one part, not one per hand" do
    expect(xpath_count(document, "//score-part")).to eq 1
  end

  it "names the part for the instrument rather than for one of its hands" do
    expect(xpath_texts(document, "//score-part/part-name")).to eq %w[piano]
  end

  it "declares both staves" do
    expect(xpath_texts(document, "//attributes/staves")).to eq %w[2]
  end

  it "gives each staff its own numbered clef" do
    expect([xpath_count(document, "//attributes/clef[@number='1']"), xpath_count(document, "//attributes/clef[@number='2']")])
      .to eq [1, 1]
  end

  it "writes the clefs the staves were authored with" do
    expect(xpath_texts(document, "//attributes/clef/sign")).to eq %w[G F]
  end

  it "numbers the two voices" do
    expect(xpath_texts(document, "//measure[@number='1']/note/voice")).to eq %w[1 2]
  end

  it "rewinds the measure between them" do
    expect(xpath_count(document, "//measure[@number='1']/backup")).to eq 1
  end

  describe "the crossing hand" do
    def staves_in(bar)
      xpath_texts(document, "//measure[@number='#{bar}']/note/staff")
    end

    it "starts on the lower staff" do
      expect(staves_in(1)).to eq %w[1 2]
    end

    it "is on the upper staff through the span" do
      expect([staves_in(2), staves_in(3)]).to eq [%w[1 1], %w[1 1]]
    end

    it "returns to the lower staff after it" do
      expect(staves_in(4)).to eq %w[1 2]
    end
  end

  describe "a grand staff with dynamics" do
    let(:flow) { MarkingFixtures.grand_staff_piano_with_dynamics }

    it "writes every part and voice dynamic as a direction" do
      expect(xpath_count(document, "//direction/direction-type/dynamics")).to eq 4
    end

    it "leaves the backup durations exactly as they are without dynamics" do
      expect(xpath_texts(document, "//backup/duration")).to eq %w[4 4 4 4]
    end

    it "writes no staff on a part's own dynamic, even on a grand staff" do
      part_levels = flow.parts.first.dynamic_events.map(&:name_key)
      xpaths = part_levels.map { |level| "//direction[direction-type/dynamics/#{level}]/staff" }
      expect(xpaths.sum { |xpath| xpath_count(document, xpath) }).to eq 0
    end

    it "numbers the voice's own dynamic with its voice and staff" do
      expect(xpath_text(document, "//direction[direction-type/dynamics/mf]/voice")).to eq "1"
      expect(xpath_text(document, "//direction[direction-type/dynamics/mf]/staff")).to eq "1"
    end
  end

  describe "a part on one staff" do
    let(:flow) { LilyPondFixtures.duo }

    it "declares no staves element" do
      expect(xpath_count(document, "//attributes/staves")).to eq 0
    end

    it "numbers no clef" do
      expect(xpath_count(document, "//attributes/clef[@number]")).to eq 0
    end

    it "puts no staff on its notes" do
      expect(xpath_count(document, "//note/staff")).to eq 0
    end

    it "puts no voice on its notes" do
      expect(xpath_count(document, "//note/voice")).to eq 0
    end
  end
end
