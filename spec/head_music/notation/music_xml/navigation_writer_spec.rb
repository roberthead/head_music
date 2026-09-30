require "spec_helper"

describe HeadMusic::Notation::MusicXML::NavigationWriter do
  subject(:writer) { described_class.new(plan) }

  let(:plan) { HeadMusic::Notation::MusicXML::RenderPlan.new(flow) }
  let(:flow) do
    flow = HeadMusic::Content::Flow.new(name: "Navigation", meter: "4/4")
    voice = flow.add_voice
    (1..3).each { |number| voice.place("#{number}:1", :whole, "C4") }
    flow
  end
  let(:bar) { flow.bars(2).last }

  def directions(lines)
    parse_musicxml("<measure>#{lines.join("\n")}</measure>")
  end

  def sounds(lines)
    REXML::XPath.match(directions(lines), "//direction/sound").map do |sound|
      attributes = {}
      sound.attributes.each { |name, value| attributes[name] = value }
      attributes
    end
  end

  it "writes nothing for an unmarked bar" do
    expect([writer.opening_lines(2), writer.closing_lines(2)]).to eq [[], []]
  end

  describe "#opening_lines" do
    it "writes a rehearsal mark above the staff" do
      bar.rehearsal_mark = "B"
      document = directions(writer.opening_lines(2))
      expect([xpath_text(document, "//direction[@placement='above']/direction-type/rehearsal"), sounds(writer.opening_lines(2))])
        .to eq ["B", []]
    end

    it "escapes the rehearsal mark's text" do
      bar.rehearsal_mark = "Verse & <Chorus>"
      expect(writer.opening_lines(2).join).to include "Verse &amp; &lt;Chorus&gt;"
    end

    it "writes a segno with the sound a D.S. returns to" do
      bar.segno = true
      document = directions(writer.opening_lines(2))
      expect([xpath_names(document, "//direction-type/*"), sounds(writer.opening_lines(2))])
        .to eq [%w[segno], [{"segno" => "segno1"}]]
    end

    it "writes a coda sign with the sound a To Coda goes to" do
      bar.coda = true
      document = directions(writer.opening_lines(2))
      expect([xpath_names(document, "//direction-type/*"), sounds(writer.opening_lines(2))])
        .to eq [%w[coda], [{"coda" => "coda1"}]]
    end

    it "writes the rehearsal mark, segno, and coda sign as separate directions" do
      bar.rehearsal_mark = "C"
      bar.segno = true
      bar.coda = true
      expect(xpath_names(directions(writer.opening_lines(2)), "//direction-type/*")).to eq %w[rehearsal segno coda]
    end
  end

  describe "#closing_lines" do
    it "writes Fine with its sound" do
      bar.fine = true
      document = directions(writer.closing_lines(2))
      expect([xpath_texts(document, "//words"), sounds(writer.closing_lines(2))]).to eq [["Fine"], [{"fine" => "yes"}]]
    end

    it "writes To Coda with its sound" do
      bar.to_coda = true
      document = directions(writer.closing_lines(2))
      expect([xpath_texts(document, "//words"), sounds(writer.closing_lines(2))])
        .to eq [["To Coda"], [{"tocoda" => "coda1"}]]
    end

    it "writes a D.S. al Coda with the sound that returns to the segno" do
      bar.jump = HeadMusic::Content::Jump.new(:dal_segno, to: :coda)
      document = directions(writer.closing_lines(2))
      expect([xpath_texts(document, "//words"), sounds(writer.closing_lines(2))])
        .to eq [["D.S. al Coda"], [{"dalsegno" => "segno1"}]]
    end

    it "writes a D.C. al Fine with the sound that returns to the start" do
      bar.jump = HeadMusic::Content::Jump.new(:da_capo, to: :fine)
      document = directions(writer.closing_lines(2))
      expect([xpath_texts(document, "//words"), sounds(writer.closing_lines(2))])
        .to eq [["D.C. al Fine"], [{"dacapo" => "yes"}]]
    end

    it "writes Fine, To Coda, and the jump in that order" do
      bar.fine = true
      bar.to_coda = true
      bar.jump = HeadMusic::Content::Jump.new(:da_capo)
      expect(xpath_texts(directions(writer.closing_lines(2)), "//words")).to eq ["Fine", "To Coda", "D.C."]
    end

    it "writes the sound after the direction type" do
      bar.fine = true
      expect(xpath_names(directions(writer.closing_lines(2)), "//direction/*")).to eq %w[direction-type sound]
    end
  end
end
