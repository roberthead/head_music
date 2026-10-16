require "spec_helper"

describe HeadMusic::Notation::MEI::StaffGroups do
  def parts_of(staff_grp)
    flow = HeadMusic::Notation::MEI.parse(mei_document(mei_staff(1, mei_note("C4", "1")), score_def: %(<scoreDef keysig="0" meter.count="4" meter.unit="4">#{staff_grp}</scoreDef>)))
    flow.parts.map { |part| [part.player&.name, part.staff_system.staves.length, part.staff_system.bracket] }
  end

  def staff_def(number, label = nil)
    inside = label ? "<label>#{label}</label>" : ""
    mei_staff_def(number, inside: inside, clef: (number == 2) ? %w[F 4] : %w[G 2])
  end

  it "reads each staff of a plain group as its own part" do
    expect(parts_of("<staffGrp>#{staff_def(1, "Flute")}#{staff_def(2, "Cello")}</staffGrp>")).to eq [["Flute", 1, :none], ["Cello", 1, :none]]
  end

  it "reads a labeled group of unlabeled staves as one part, as the writer and MuseScore write a piano" do
    group = %(<staffGrp><staffGrp symbol="brace"><label>Piano</label>#{staff_def(1)}#{staff_def(2)}</staffGrp></staffGrp>)
    expect(parts_of(group)).to eq [["Piano", 2, :brace]]
  end

  it "reads an unlabeled braced group as one part" do
    expect(parts_of(%(<staffGrp><staffGrp symbol="brace">#{staff_def(1)}#{staff_def(2)}</staffGrp></staffGrp>))).to eq [[nil, 2, :brace]]
  end

  it "reads a braced group whose staves share one label as one part" do
    group = %(<staffGrp symbol="brace">#{staff_def(1, "Harp")}#{staff_def(2, "Harp")}</staffGrp>)
    expect(parts_of(group).map { |part| part.take(2) }).to eq [[nil, 2]]
  end

  it "reads a group of labeled staves as separate parts, labeling none from the group" do
    group = %(<staffGrp><staffGrp symbol="bracket"><label>Choir</label>#{staff_def(1, "S")}#{staff_def(2, "A")}</staffGrp></staffGrp>)
    expect(parts_of(group)).to eq [["S", 1, :none], ["A", 1, :none]]
  end

  describe "an unlabeled group of unlabeled staves, not braced" do
    def parts_with(*layer_numbers)
      group = %(<staffGrp><staffGrp symbol="bracket">#{staff_def(1)}#{staff_def(2)}</staffGrp></staffGrp>)
      measure = layer_numbers.each_with_index.map { |number, index| mei_staff(index + 1, [number, mei_note("C4", "1")]) }.join
      flow = HeadMusic::Notation::MEI.parse(mei_document(measure, score_def: %(<scoreDef keysig="0" meter.count="4" meter.unit="4">#{group}</scoreDef>)))
      flow.parts.map { |part| [part.staff_system.staves.length, part.voices.length] }
    end

    it "is one part where no measure has one layer number on two of its staves, as the writer numbers a choir's layers" do
      expect(parts_with(1, 2)).to eq [[2, 2]]
    end

    it "is a part of each staff where a measure has one layer number on two of them, as a group of instruments does" do
      expect(parts_with(1, 1)).to eq [[1, 1], [1, 1]]
    end
  end

  it "sets a multi-staff part's bracket from its @symbol" do
    group = %(<staffGrp><staffGrp symbol="bracket"><label>Organ</label>#{staff_def(1)}#{staff_def(2)}</staffGrp></staffGrp>)
    expect(parts_of(group)).to eq [["Organ", 2, :bracket]]
  end

  it "reads MEI 4's @label" do
    expect(parts_of(%(<staffGrp>#{mei_staff_def(1, attributes: %( label="Oboe"))}</staffGrp>)).first.first).to eq "Oboe"
  end

  it "raises on two staff definitions of one number" do
    expect { parts_of("<staffGrp>#{staff_def(1)}#{staff_def(1)}</staffGrp>") }
      .to raise_error(HeadMusic::Notation::MEI::ParseError, /Two <staffDef>s are numbered 1/)
  end
end
