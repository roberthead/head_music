require "spec_helper"

describe HeadMusic::Notation::MusicXML::BarlineWriter do
  subject(:writer) { described_class.new(plan) }

  let(:plan) { HeadMusic::Notation::MusicXML::RenderPlan.new(flow) }
  let(:flow) do
    flow = HeadMusic::Content::Flow.new(name: "Barlines", meter: "4/4")
    voice = flow.add_voice
    (1..5).each { |number| voice.place("#{number}:1", :whole, "C4") }
    flow
  end

  def bar(number)
    flow.bars(number).last
  end

  def document(lines)
    parse_musicxml(lines.join("\n"))
  end

  def children(lines)
    xpath_names(document(lines), "/barline/*")
  end

  def bar_style(lines)
    xpath_text(document(lines), "/barline/bar-style")
  end

  def attributes_of(lines, xpath)
    attributes = {}
    REXML::XPath.first(document(lines), xpath).attributes.each { |name, value| attributes[name] = value }
    attributes
  end

  describe "#right_lines" do
    it "writes nothing for a regular barline before the last bar" do
      expect(writer.right_lines(2)).to eq []
    end

    it "draws the implied final barline on the last bar" do
      expect(bar_style(writer.right_lines(5))).to eq "light-heavy"
    end

    it "writes the right barline at the right" do
      expect(attributes_of(writer.right_lines(5), "/barline")).to eq("location" => "right")
    end

    {double: "light-light", final: "light-heavy", dashed: "dashed", dotted: "dotted"}.each do |barline, style|
      it "writes a #{barline} barline as #{style}" do
        bar(2).barline = barline
        expect(bar_style(writer.right_lines(2))).to eq style
      end
    end

    it "keeps a styled barline on the last bar" do
      bar(5).barline = :double
      expect(bar_style(writer.right_lines(5))).to eq "light-light"
    end

    context "with a repeat end" do
      before { bar(2).ends_repeat_after_num_plays = 2 }

      it "writes a light-heavy backward repeat" do
        expect(children(writer.right_lines(2))).to eq %w[bar-style repeat]
      end

      it "leaves out times for a repeat played twice" do
        expect(attributes_of(writer.right_lines(2), "/barline/repeat")).to eq("direction" => "backward")
      end

      it "outranks the bar's own barline style" do
        bar(2).barline = :double
        expect(bar_style(writer.right_lines(2))).to eq "light-heavy"
      end
    end

    it "writes times for a repeat played 3 times" do
      bar(2).ends_repeat_after_num_plays = 3
      expect(attributes_of(writer.right_lines(2), "/barline/repeat")).to eq("direction" => "backward", "times" => "3")
    end
  end

  describe "#left_lines" do
    it "writes nothing for a bar that starts neither a repeat nor an ending" do
      expect(writer.left_lines(2)).to eq []
    end

    context "with a repeat start" do
      before { bar(2).starts_repeat = true }

      it "writes a left barline" do
        expect(attributes_of(writer.left_lines(2), "/barline")).to eq("location" => "left")
      end

      it "writes a heavy-light forward repeat" do
        expect([bar_style(writer.left_lines(2)), attributes_of(writer.left_lines(2), "/barline/repeat")])
          .to eq ["heavy-light", {"direction" => "forward"}]
      end
    end
  end

  context "with 1st and 2nd endings" do
    before do
      bar(1).starts_repeat = true
      bar(2).plays_on_passes = [1]
      bar(3).plays_on_passes = [1]
      bar(3).ends_repeat_after_num_plays = 2
      bar(4).plays_on_passes = [2]
    end

    it "starts the 1st ending where its run of bars begins" do
      expect(xpath_text(document(writer.left_lines(2)), "/barline/ending")).to eq "1."
    end

    it "writes the ending start's number and type" do
      expect(attributes_of(writer.left_lines(2), "/barline/ending")).to eq("number" => "1", "type" => "start")
    end

    it "writes no ending within the run" do
      expect([writer.left_lines(3), writer.right_lines(2)]).to eq [[], []]
    end

    it "stops the 1st ending at the repeat end, in schema order" do
      expect(children(writer.right_lines(3))).to eq %w[bar-style ending repeat]
    end

    it "stops the 1st ending with a downward jog" do
      expect(attributes_of(writer.right_lines(3), "/barline/ending")).to eq("number" => "1", "type" => "stop")
    end

    it "starts the 2nd ending" do
      expect(attributes_of(writer.left_lines(4), "/barline/ending")).to eq("number" => "2", "type" => "start")
    end

    it "discontinues the 2nd ending, which has no repeat end" do
      expect(attributes_of(writer.right_lines(4), "/barline/ending")).to eq("number" => "2", "type" => "discontinue")
    end

    it "writes an empty stop" do
      expect(xpath_text(document(writer.right_lines(3)), "/barline/ending")).to be_nil
    end
  end

  context "with an ending played on more than one pass" do
    before do
      bar(2).plays_on_passes = [1, 2]
      bar(2).ends_repeat_after_num_plays = 3
      bar(3).plays_on_passes = [3]
    end

    it "lists the passes in the number and the text" do
      lines = writer.left_lines(2)
      expect([attributes_of(lines, "/barline/ending")["number"], xpath_text(document(lines), "/barline/ending")])
        .to eq ["1, 2", "1, 2."]
    end
  end

  context "with a repeat and an ending starting on one bar" do
    before do
      bar(2).starts_repeat = true
      bar(2).plays_on_passes = [1]
      bar(2).ends_repeat_after_num_plays = 2
    end

    it "writes the bar style, the ending, and the repeat in schema order" do
      expect(children(writer.left_lines(2))).to eq %w[bar-style ending repeat]
    end
  end
end
