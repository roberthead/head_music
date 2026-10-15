require "spec_helper"

describe HeadMusic::Notation::MusicXML::BarlineReader do
  def whole_note
    note_xml("C4", 4, "whole")
  end

  def barline_xml(location, inner)
    %(<barline location="#{location}">#{inner}</barline>)
  end

  def style_xml(style)
    "<bar-style>#{style}</bar-style>"
  end

  def ending_xml(number, type)
    %(<ending number="#{number}" type="#{type}"/>)
  end

  def repeat_xml(direction, times: nil)
    %(<repeat direction="#{direction}"#{times && %( times="#{times}")}/>)
  end

  def parse(*parts)
    parse_musicxml_flow(musicxml_document(*parts))
  end

  def barline_markings(flow)
    flow.bars.map { |bar| bar.to_h.slice("starts_repeat", "ends_repeat_after_num_plays", "plays_on_passes", "barline") }
  end

  describe "bar styles" do
    let(:flow) do
      parse([
        whole_note + barline_xml("right", style_xml("light-light")),
        whole_note + barline_xml("right", style_xml("dashed")),
        whole_note + barline_xml("right", style_xml("dotted")),
        whole_note + barline_xml("right", style_xml("light-heavy")),
        whole_note,
        barline_xml("left", style_xml("light-light")) + whole_note + barline_xml("right", style_xml("light-heavy"))
      ])
    end

    it "inverts the writer's bar styles" do
      expect(flow.bars.first(4).map(&:barline)).to eq %i[double dashed dotted final]
    end

    it "closes the bar before a left barline" do
      expect(flow.bars[4].barline).to eq :double
    end

    it "takes the final barline on the last bar as the implied one" do
      expect(flow.bars.last.barline).to eq :regular
    end
  end

  it "skips bar styles the model has no name for" do
    flow = parse([whole_note + barline_xml("right", style_xml("heavy-heavy")), whole_note])
    expect(flow.bars.map(&:barline)).to eq %i[regular regular]
  end

  it "skips a left barline on the first bar" do
    flow = parse([barline_xml("left", style_xml("light-light")) + whole_note, whole_note])
    expect(barline_markings(flow)).to eq [{}, {}]
  end

  describe "repeats" do
    let(:flow) do
      parse([
        whole_note,
        barline_xml("left", style_xml("heavy-light") + repeat_xml("forward")) + whole_note,
        whole_note + barline_xml("right", style_xml("light-heavy") + repeat_xml("backward")),
        whole_note + barline_xml("right", style_xml("light-heavy") + repeat_xml("backward", times: 3)),
        whole_note
      ])
    end

    it "reads each repeat's start, end, and play count, and leaves the repeat signs' own styles alone" do
      expect(barline_markings(flow)).to eq [
        {}, {"starts_repeat" => true}, {"ends_repeat_after_num_plays" => 2}, {"ends_repeat_after_num_plays" => 3}, {}
      ]
    end
  end

  describe "endings" do
    let(:flow) do
      parse([
        barline_xml("left", repeat_xml("forward")) + whole_note,
        barline_xml("left", ending_xml("1, 2", "start")) + whole_note,
        whole_note + barline_xml("right", ending_xml("1, 2", "stop") + repeat_xml("backward", times: 3)),
        barline_xml("left", ending_xml("3 4", "start")) + whole_note + barline_xml("right", ending_xml("3 4", "discontinue")),
        whole_note
      ])
    end

    it "runs each ending from its start to its stop or discontinue, splitting its number list" do
      expect(flow.bars.map(&:plays_on_passes)).to eq [nil, [1, 2], [1, 2], [3, 4], nil]
    end
  end

  it "drops an ending stop with no start and an ending with an unreadable number" do
    flow = parse([
      whole_note + barline_xml("right", ending_xml("1", "stop")),
      barline_xml("left", ending_xml("one", "start")) + whole_note + barline_xml("right", ending_xml("one", "stop"))
    ])
    expect(flow.bars.map(&:plays_on_passes)).to eq [nil, nil]
  end

  describe "a barline inside a bar" do
    let(:flow) do
      parse([
        whole_note,
        [note_xml("C4", 2, "half") + barline_xml("right", style_xml("light-heavy") + repeat_xml("backward")), {number: "2"}],
        [barline_xml("left", style_xml("heavy-light") + repeat_xml("forward")) + note_xml("D4", 2, "half"), {number: "X1", implicit: true}],
        whole_note
      ])
    end

    it "closes the bar it falls in and opens the next" do
      expect(barline_markings(flow)).to eq [{}, {"ends_repeat_after_num_plays" => 2}, {"starts_repeat" => true}]
    end
  end

  describe "over several parts" do
    let(:flow) do
      parse(
        [whole_note + barline_xml("right", style_xml("dashed")), whole_note],
        [whole_note + barline_xml("right", style_xml("dotted") + repeat_xml("backward")), whole_note]
      )
    end

    it "takes the first value found for each bar" do
      expect(flow.bars.first.barline).to eq :dashed
    end

    it "takes a repeat from any part" do
      expect(flow.bars.first.ends_repeat_after_num_plays).to eq 2
    end
  end

  it "keeps a final barline :regular where another part ends a repeat" do
    flow = parse(
      [whole_note + barline_xml("right", style_xml("light-heavy")), whole_note],
      [whole_note + barline_xml("right", style_xml("light-heavy") + repeat_xml("backward")), whole_note]
    )
    expect(barline_markings(flow).first).to eq("ends_repeat_after_num_plays" => 2)
  end

  describe "round trips through the writer" do
    def round_trip(flow)
      HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(flow))
    end

    def multipart_repeats
      flow = HeadMusic::Content::Flow.new(name: "Repeats", key_signature: "C major", meter: "4/4")
      2.times do
        voice = flow.add_voice
        (1..6).each { |number| voice.place("#{number}:1", :whole, "C4") }
      end
      bars = flow.bars
      bars[1].starts_repeat = true
      bars[2].plays_on_passes = [1, 2]
      bars[2].ends_repeat_after_num_plays = 3
      bars[3].plays_on_passes = [3]
      bars[3].barline = :double
      bars[4].barline = :final
      flow
    end

    {
      "NavigationFixtures.dal_segno_al_coda" => -> { NavigationFixtures.dal_segno_al_coda },
      "NavigationFixtures.da_capo_al_fine" => -> { NavigationFixtures.da_capo_al_fine },
      "LilyPondFixtures.dal_segno_al_coda" => -> { LilyPondFixtures.dal_segno_al_coda },
      "LilyPondFixtures.barline_styles" => -> { LilyPondFixtures.barline_styles },
      "Speed the Plough" => -> { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) },
      "repeats and endings over two parts" => -> { multipart_repeats },
      **%i[suite single_flow_project trio clarinet_project mixed_ensemble].to_h do |name|
        ["LayoutFixtures.#{name}", -> { LayoutFixtures.public_send(name).flows.first }]
      end
    }.each do |name, build|
      it "keeps the barlines, repeats, and endings of #{name}" do
        flow = instance_exec(&build)
        expect(barline_markings(round_trip(flow))).to eq barline_markings(flow)
      end
    end
  end
end
