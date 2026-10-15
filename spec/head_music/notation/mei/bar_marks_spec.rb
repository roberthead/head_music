require "spec_helper"

describe HeadMusic::Notation::MEI::BarMarks do
  def document(flow)
    parse_mei(HeadMusic::Notation::MEI.render(flow))
  end

  def barlines(flow)
    mei_attributes(document(flow), "//mei:measure", "n", "left", "right")
  end

  def abc(body, meter: "2/4")
    HeadMusic::Notation::ABC.parse("X:1\nT:Bars\nM:#{meter}\nL:1/4\nK:C\n#{body}\n")
  end

  it "writes each barline style, and a final barline on the last bar" do
    expect(barlines(LilyPondFixtures.barline_styles).map(&:last)).to eq ["end", "dashed", "dotted", nil, "end"]
  end

  it "writes a double barline" do
    expect(barlines(NavigationFixtures.dal_segno_al_coda)[3]).to eq ["4", nil, "dbl"]
  end

  it "writes a final barline on a last bar left regular" do
    expect(barlines(abc("CD|EF|"))).to eq [["1", nil, nil], ["2", nil, "end"]]
  end

  it "writes the start and end of a repeat" do
    expect(barlines(abc("|: CD | EF :| GA |]"))).to eq [["1", "rptstart", nil], ["2", nil, "rptend"], ["3", nil, "end"]]
  end

  it "ends the last bar with its repeat rather than a final barline" do
    expect(barlines(abc("|: CD | EF :|")).last).to eq ["2", nil, "rptend"]
  end

  describe "endings" do
    let(:xml) { document(NavigationFixtures.da_capo_al_fine) }

    it "wraps the bars of each ending, numbered and labeled by its passes" do
      endings = mei_elements(xml, "//mei:section/mei:ending").map do |ending|
        [ending.attributes["n"], ending.attributes["label"], ending.get_elements("measure").map { |measure| measure.attributes["n"] }]
      end
      expect(endings).to eq [["1", "1.", ["2"]], ["2", "2.", ["3"]]]
    end

    it "leaves the other bars in the section" do
      expect(mei_attributes(xml, "//mei:section/mei:measure", "n")).to eq %w[1 4 5 6 7]
    end

    it "joins several passes into one ending" do
      flow = abc("|: CD |[1,2 EF :|[3 GA |]").tap { |volta| volta.bar(2).ends_repeat_after_num_plays = 3 }
      endings = mei_elements(document(flow), "//mei:ending").map { |ending| mei_attribute_hash(ending) }
      expect(endings).to eq [{"xml:id" => "m1-ending-b2", "n" => "1-2", "label" => "1., 2."}, {"xml:id" => "m1-ending-b3", "n" => "3", "label" => "3."}]
    end

    it "starts a new ending after a repeat even on the same passes" do
      flow = abc("|: C D |[1 E F :|[1 G A :| B c |]").tap { |volta| volta.bar(3).ends_repeat_after_num_plays = 2 }
      expect(mei_attributes(document(flow), "//mei:ending", "xml:id")).to eq %w[m1-ending-b2 m1-ending-b3]
    end

    it "holds a change written before its first bar" do
      allow(HeadMusic::Notation::MEI::SectionWriter).to receive(:pre_measure_sources).and_return([MEIExtensionStubs::EveryHook])
      expect(mei_attributes(xml, "//mei:ending[@n='1']/*", "xml:id")).to eq %w[m1-scoredef-b2 m1-staffdef-b2s1 m1-measure-b2]
    end
  end
end
