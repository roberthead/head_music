require "spec_helper"

# A voice belongs to a part and has a staff at any given moment, so a piano
# voice can start in the bass staff and cross into the treble without leaving
# its part. LilyPond wants \change Staff at the span boundaries -- which is
# exactly where the staff-assignment map holds its events.
describe HeadMusic::Notation::LilyPond::Writer do
  subject(:rendered) { described_class.new(flow).to_s }

  let(:flow) { LilyPondFixtures.cross_staff_piano }

  it "groups the part's staves under one brace" do
    expect(rendered).to include "\\new PianoStaff <<"
  end

  it "emits one staff per staff of the system, each named" do
    expect(rendered.scan(/\\new Staff = "[^"]+"/))
      .to eq ['\\new Staff = "part1-staff1"', '\\new Staff = "part1-staff2"']
  end

  it "does not emit a separate staff per voice" do
    expect(rendered.scan("\\new Staff").length).to eq 2
  end

  it "changes staff at the start of the span" do
    expect(rendered).to include %(\\change Staff = "part1-staff1")
  end

  it "changes back at the end of the span" do
    expect(rendered).to include %(\\change Staff = "part1-staff2")
  end

  it "emits a change at each boundary and nowhere else" do
    expect(rendered.scan("\\change Staff").length).to eq 2
  end

  it "writes each staff in its authored clef rather than a guessed one" do
    expect(rendered.scan(/\\clef \w+/)).to eq ["\\clef treble", "\\clef bass"]
  end

  it "is structurally valid" do
    expect_structurally_valid_lilypond(rendered, bars: 4, voices: 2)
  end

  it_behaves_like "a compilable document"

  # A staff nobody is written on still has to appear, or the grand staff loses
  # a line of the system and the piano looks like a flute.
  describe "a staff with no voice on it" do
    subject(:rendered) { described_class.new(flow).to_s }

    let(:flow) { LilyPondFixtures.one_handed_piano }

    it "still emits both staves" do
      expect(rendered.scan(/\\new Staff = "[^"]+"/).length).to eq 2
    end

    it "fills the empty staff with whole-bar rests" do
      expect(rendered.scan("R1*4/4").length).to eq 2
    end

    it "gives the empty staff its authored clef" do
      expect(rendered).to include "\\clef bass"
    end

    it "carries a stream per staff rather than per voice" do
      expect_structurally_valid_lilypond(rendered, bars: 2, voices: 1, streams: 2)
    end

    it_behaves_like "a compilable document"
  end
end
