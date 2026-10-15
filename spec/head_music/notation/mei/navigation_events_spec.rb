require "spec_helper"

describe HeadMusic::Notation::MEI::NavigationEvents do
  def document(flow)
    parse_mei(HeadMusic::Notation::MEI.render(flow))
  end

  def marks(flow, xpath = "//mei:measure/*[self::mei:reh or self::mei:repeatMark or self::mei:dir]")
    mei_elements(document(flow), xpath).map do |mark|
      [mark.parent.attributes["n"], mark.name, mark.attributes["func"], mark.attributes["tstamp"], mark.text]
    end
  end

  it "writes rehearsal marks, the segno, and the coda where their bars open" do
    expect(marks(NavigationFixtures.dal_segno_al_coda).select { |mark| mark[3] == "0" }).to eq [
      ["1", "reh", nil, "0", "A"], ["2", "repeatMark", "segno", "0", nil], ["3", "reh", nil, "0", "B"], ["5", "repeatMark", "coda", "0", nil]
    ]
  end

  it "writes To Coda and the D.S. with their text where their bars close" do
    expect(marks(NavigationFixtures.dal_segno_al_coda).reject { |mark| mark[3] == "0" }).to eq [
      ["3", "repeatMark", "coda", "5", "To Coda"], ["4", "repeatMark", "dalSegno", "5", "D.S. al Coda"]
    ]
  end

  it "writes the Fine and the D.C. at the end of their bars" do
    expect(marks(NavigationFixtures.da_capo_al_fine, "//mei:repeatMark")).to eq [
      ["3", "repeatMark", "fine", "4", "Fine"],
      ["7", "repeatMark", "daCapo", "4", "D.C. al Fine"]
    ]
  end

  it "writes every mark on the score's top staff" do
    flow = LilyPondFixtures.cross_staff_piano.tap { |piano| piano.bar(2).rehearsal_mark = "A" }
    expect(mei_attributes(document(flow), "//mei:reh", "staff")).to eq ["1"]
  end

  it "writes the plays of a repeat played more than twice at the end of its bar" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nT:Thrice\nM:3/4\nL:1/4\nK:C\n|: C D E :| F G A |]\n")
    flow.bar(1).ends_repeat_after_num_plays = 3
    expect(marks(flow)).to eq [["1", "dir", nil, "4", "×3"]]
  end

  it "says nothing of a repeat played twice" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nT:Twice\nM:3/4\nL:1/4\nK:C\n|: C D E :| F G A |]\n")
    expect(marks(flow)).to eq []
  end
end
