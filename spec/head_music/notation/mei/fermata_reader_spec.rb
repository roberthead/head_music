require "spec_helper"

describe HeadMusic::Notation::MEI::FermataReader do
  def read(*items, **options)
    stub_const("HeadMusic::Notation::MEI::MARK_READERS", [described_class])
    HeadMusic::Notation::MEI.parse(mei_document(*items, **options))
  end

  def fermatas(flow)
    flow.fermatas.map { |fermata| [fermata.from.to_s, fermata.to.to_s] }
  end

  let(:two_staves) { mei_score_def(clefs: [%w[G 2], %w[F 4]]) }

  it "reads @fermata on a note as a fermata over its span" do
    flow = read(mei_staff(1, mei_note("C4", "2") + mei_note("D4", "2", fermata: "above")))
    expect(fermatas(flow)).to eq [["1:3:000", "2:1:000"]]
  end

  it "reads @fermata on a rest, a chord, and a chord tone" do
    flow = read(
      mei_staff(1, mei_rest("2", fermata: "above") + mei_note("C4", "2")),
      mei_staff(1, %(<chord dur="2" fermata="above"><note pname="c" oct="4"/><note pname="e" oct="4"/></chord><chord dur="2"><note pname="d" oct="4" fermata="below"/><note pname="f" oct="4"/></chord>))
    )
    expect(fermatas(flow)).to eq [["1:1:000", "1:3:000"], ["2:1:000", "2:3:000"], ["2:3:000", "3:1:000"]]
  end

  it "reads @fermata on a whole-bar rest, a general pause" do
    flow = read(mei_staff(1, mei_note("C4", "1")), mei_staff(1, %(<mRest fermata="above"/>)), mei_staff(1, mei_note("C4", "1")))
    expect(fermatas(flow)).to eq [["2:1:000", "3:1:000"]]
  end

  it "skips a mark on a whole-bar rest the voice is tacet in" do
    flow = read(mei_staff(1, mei_note("C4", "1")), mei_staff(1, %(<mRest fermata="above"/>)))
    expect(flow.fermatas).to be_empty
  end

  it "reads a <fermata> at the event its @startid names" do
    flow = read(mei_staff(1, mei_note("C4", "2") + mei_note("D4", "2", "xml:id": "d")) + %(<fermata staff="1" startid="#d"/>))
    expect(fermatas(flow)).to eq [["1:3:000", "2:1:000"]]
  end

  it "resolves a @startid naming an event in an earlier measure" do
    flow = read(mei_staff(1, mei_note("C4", "2") + mei_note("D4", "2", "xml:id": "d")), mei_staff(1, mei_note("E4", "1")) + %(<fermata staff="1" startid="#d"/>))
    expect(fermatas(flow)).to eq [["1:3:000", "2:1:000"]]
  end

  it "reads a <fermata> by @tstamp alone on the events of its staff sounding there" do
    flow = read(mei_staff(1, mei_note("C4", "2") + mei_note("D4", "2")) + %(<fermata staff="1" tstamp="3"/>))
    expect(fermatas(flow)).to eq [["1:3:000", "2:1:000"]]
  end

  it "reads a <fermata> by @tstamp inside a held note from that moment to the note's end" do
    flow = read(mei_staff(1, mei_note("C4", "1")) + %(<fermata staff="1" tstamp="2"/>))
    expect(fermatas(flow)).to eq [["1:2:000", "2:1:000"]]
  end

  it "reads a <fermata> by @tstamp naming no staff on every voice" do
    music = mei_staff(1, mei_note("C5", "1")) + mei_staff(2, mei_note("C3", "2") + mei_note("G2", "2"))
    flow = read(music + %(<fermata tstamp="3"/>), score_def: two_staves)
    expect(fermatas(flow)).to eq [["1:3:000", "2:1:000"]]
  end

  it "counts a mark written both by @fermata and by <fermata> once" do
    flow = read(mei_staff(1, mei_note("C4", "1", "xml:id": "c", fermata: "above")) + %(<fermata staff="1" startid="#c" tstamp="1"/>))
    expect(fermatas(flow)).to eq [["1:1:000", "2:1:000"]]
  end

  it "forms one fermata of marks whose events sound together, from the latest start to the earliest end" do
    music = mei_staff(1, mei_note("C5", "2") + mei_note("B4", "2", fermata: "above")) +
      mei_staff(2, mei_note("C3", "2") + mei_note("D3", "4") + mei_note("G2", "4", fermata: "below"))
    expect(fermatas(read(music, score_def: two_staves))).to eq [["1:4:000", "2:1:000"]]
  end

  it "holds a mark on a tie's later link from that link" do
    flow = read(mei_staff(1, mei_note("C4", "2") + mei_note("D4", "2", tie: "i")), mei_staff(1, mei_note("D4", "2", tie: "t", fermata: "above") + mei_note("E4", "2")))
    expect(fermatas(flow)).to eq [["2:1:000", "2:3:000"]]
  end

  it "skips a mark on a grace note" do
    flow = read(mei_staff(1, mei_note("B3", "8", grace: "unacc", fermata: "above") + mei_note("C4", "1")))
    expect(flow.fermatas).to be_empty
  end
end
