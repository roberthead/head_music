require "spec_helper"

describe HeadMusic::Notation::MEI::NavigationReader do
  def marks(*controls, bars: 2, staves: 1)
    measures = (1..bars).map do |number|
      staff_xml = (1..staves).map { |staff| mei_staff(staff, mei_note("C4", "1", "xml:id": "n#{number}-#{staff}")) }.join
      %(<measure n="#{number}">#{staff_xml}#{controls.fetch(number - 1, "")}</measure>)
    end
    flow = HeadMusic::Notation::MEI.parse(mei_document(*measures, score_def: mei_score_def(clefs: [%w[G 2]] * staves)))
    flow.bars.to_h { |bar| [bar.number, bar.to_h] }.reject { |_, marks| marks.empty? }
  end

  def repeat_mark(func, text = nil, tstamp: "5")
    func_attribute = func ? %( func="#{func}") : ""
    %(<repeatMark#{func_attribute} staff="1" tstamp="#{tstamp}">#{text}</repeatMark>)
  end

  it "reads a <reh> as its bar's rehearsal mark, through its markup" do
    expect(marks(%(<reh staff="1" tstamp="0"><rend fontweight="bold">A</rend></reh>))).to eq(1 => {"rehearsal_mark" => "A"})
  end

  it "skips an empty <reh>, so that the next one in its bar stands" do
    expect(marks(%(<reh staff="1" tstamp="1"> </reh><reh staff="1" tstamp="1">A</reh>))).to eq(1 => {"rehearsal_mark" => "A"})
  end

  it "lets the first rehearsal mark of a bar win, on any staff" do
    expect(marks(%(<reh staff="2" tstamp="1">B</reh><reh staff="1" tstamp="1">A</reh>), staves: 2)).to eq(1 => {"rehearsal_mark" => "B"})
  end

  it "reads segno, coda, and Fine by @func" do
    expect(marks(repeat_mark("segno", tstamp: "0") + repeat_mark("fine", "Fine"), repeat_mark("coda", tstamp: "0")))
      .to eq(1 => {"segno" => true, "fine" => true}, 2 => {"coda" => true})
  end

  it "tells To Coda from a coda sign by its text" do
    expect(marks(repeat_mark("coda", "To Coda"))).to eq(1 => {"to_coda" => true})
  end

  it "reads D.C. and D.S. by @func, with al Fine and al Coda from their text" do
    expect(marks(repeat_mark("daCapo", "D.C. al Fine"), repeat_mark("dalSegno", "Dal Segno al Coda"))).to eq(
      1 => {"jump" => {"kind" => "da_capo", "to" => "fine"}}, 2 => {"jump" => {"kind" => "dal_segno", "to" => "coda"}}
    )
  end

  it "reads a jump with no target where its text names none" do
    expect(marks(repeat_mark("dalSegno", "𝄋"))).to eq(1 => {"jump" => {"kind" => "dal_segno"}})
  end

  it "reads a <repeatMark> with no @func, and a <dir>, by their words" do
    expect(marks(repeat_mark(nil, "D.S. al Fine") + %(<dir staff="1" tstamp="1">\u{E047}</dir>), %(<dir staff="1" tstamp="5">Fine</dir>)))
      .to eq(1 => {"segno" => true, "jump" => {"kind" => "dal_segno", "to" => "fine"}}, 2 => {"fine" => true})
  end

  it "skips words that do not navigate" do
    expect(marks(%(<dir staff="1" tstamp="1">dolce</dir>) + repeat_mark("volta", "bis"), repeat_mark("volta", "Fine")))
      .to eq(2 => {"fine" => true})
  end

  it "places a control at the bar of the event its @startid names" do
    expect(marks(%(<repeatMark func="fine" startid="#n2-1">Fine</repeatMark>))).to eq(2 => {"fine" => true})
  end
end
