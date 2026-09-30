require "spec_helper"

describe HeadMusic::Notation::MusicXML::Writer do
  let(:document) { parse_musicxml(described_class.new(flow).to_s) }

  def flow_of(bar_count, voice_count: 1)
    flow = HeadMusic::Content::Flow.new(name: "Bar Markings", meter: "4/4")
    voice_count.times do
      voice = flow.add_voice
      (1..bar_count).each { |number| voice.place("#{number}:1", :whole, "C4") }
    end
    flow
  end

  def bar(number)
    flow.bars(number).last
  end

  def measure_children(part, number)
    xpath_names(document, "//part[@id='#{part}']/measure[@number='#{number}']/*")
  end

  context "with a D.S. al Coda" do
    let(:flow) do
      flow = flow_of(5)
      bars = flow.bars(5)
      bars[0].rehearsal_mark = "A"
      bars[1].segno = true
      bars[2].rehearsal_mark = "B"
      bars[2].to_coda = true
      bars[3].jump = HeadMusic::Content::Jump.new(:dal_segno, to: :coda)
      bars[3].barline = :double
      bars[4].coda = true
      flow
    end

    it "marks the rehearsal letters at the start of their measures" do
      expect(xpath_texts(document, "//measure/direction/direction-type/rehearsal")).to eq %w[A B]
    end

    it "sets the segno in bar 2" do
      expect(xpath_count(document, "//measure[@number='2']/direction[direction-type/segno]/sound[@segno='segno1']")).to eq 1
    end

    it "writes To Coda after the notes of bar 3" do
      expect([measure_children("P1", 3).last, xpath_text(document, "//measure[@number='3']/direction[sound/@tocoda='coda1']/direction-type/words")])
        .to eq ["direction", "To Coda"]
    end

    it "writes the D.S. al Coda and its double barline in bar 4" do
      expect([measure_children("P1", 4), xpath_text(document, "//measure[@number='4']/barline/bar-style")])
        .to eq [%w[note direction barline], "light-light"]
    end

    it "jumps back to the segno" do
      expect(xpath_text(document, "//measure[@number='4']/direction[sound/@dalsegno='segno1']/direction-type/words")).to eq "D.S. al Coda"
    end

    it "sets the coda sign in bar 5, before its notes" do
      expect([measure_children("P1", 5), xpath_count(document, "//measure[@number='5']/direction[direction-type/coda]/sound[@coda='coda1']")])
        .to eq [%w[direction note barline], 1]
    end

    it "ends with a final barline" do
      expect(xpath_text(document, "//measure[@number='5']/barline[@location='right']/bar-style")).to eq "light-heavy"
    end
  end

  context "with a rehearsal mark over two parts" do
    let(:flow) { flow_of(2, voice_count: 2) }

    before { bar(2).rehearsal_mark = "B" }

    it "writes the rehearsal mark in every part" do
      expect(xpath_texts(document, "//part/measure[@number='2']/direction/direction-type/rehearsal")).to eq %w[B B]
    end

    it "writes the final barline in every part" do
      expect(xpath_count(document, "//part/measure[@number='2']/barline/bar-style")).to eq 2
    end
  end

  context "with a repeat and 1st and 2nd endings" do
    let(:flow) { flow_of(5) }

    before do
      bar(2).starts_repeat = true
      bar(3).plays_on_passes = [1]
      bar(3).ends_repeat_after_num_plays = 2
      bar(4).plays_on_passes = [2]
      bar(4).barline = :double
    end

    it "opens a repeat with a left barline before the attributes and notes" do
      bar(1).starts_repeat = true
      expect(measure_children("P1", 1)).to eq %w[barline attributes note]
    end

    it "writes each ending's start and end" do
      endings = REXML::XPath.match(document, "//barline/ending").map { |ending| [ending.attributes["number"], ending.attributes["type"]] }
      expect(endings).to eq [%w[1 start], %w[1 stop], %w[2 start], %w[2 discontinue]]
    end

    it "writes the repeats" do
      expect(xpath_names(document, "//barline/repeat").length).to eq 2
    end

    it "writes the bar styles" do
      expect(xpath_texts(document, "//barline/bar-style")).to eq %w[heavy-light light-heavy light-light light-heavy]
    end
  end

  context "with a repeat played 3 times" do
    let(:flow) { flow_of(2) }

    before { bar(1).ends_repeat_after_num_plays = 3 }

    it "writes the play count on the backward repeat" do
      expect(REXML::XPath.match(document, "//barline/repeat").map { |repeat| repeat.attributes["times"] }).to eq ["3"]
    end
  end

  context "with every marking on one bar" do
    let(:flow) { flow_of(3) }

    before do
      bar(2).starts_repeat = true
      bar(2).rehearsal_mark = "C"
      bar(2).segno = true
      bar(2).fine = true
      bar(2).ends_repeat_after_num_plays = 2
      flow.parts.first.place_dynamic("2:1", :p)
    end

    it "writes the left barline first, the navigation around the notes, and the right barline last" do
      expect(measure_children("P1", 2)).to eq %w[barline direction direction direction note direction barline]
    end
  end
end
