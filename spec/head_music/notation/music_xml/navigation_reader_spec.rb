require "spec_helper"

describe HeadMusic::Notation::MusicXML::NavigationReader do
  def whole_note
    note_xml("C4", 4, "whole")
  end

  def direction_xml(signs, sound = nil)
    "<direction><direction-type>#{signs}</direction-type>#{sound && "<sound #{sound}/>"}</direction>"
  end

  def words_xml(text)
    "<words>#{text}</words>"
  end

  def parse(*parts)
    parse_musicxml_flow(musicxml_document(*parts))
  end

  def bar_markings(flow)
    flow.bars.map(&:to_h)
  end

  def first_bar(*directions)
    parse([directions.join + whole_note, whole_note]).bars.first
  end

  describe "signs with their sounds" do
    it "reads a segno" do
      expect(first_bar(direction_xml("<segno/>", %(segno="segno1")))).to be_segno
    end

    it "reads a coda sign" do
      expect(first_bar(direction_xml("<coda/>", %(coda="coda1")))).to be_coda
    end

    it "reads a coda sign whose sound says To Coda as To Coda" do
      expect(first_bar(direction_xml("<coda/>", %(tocoda="coda1"))).to_h).to eq("to_coda" => true)
    end

    it "reads Fine" do
      expect(first_bar(direction_xml(words_xml("Fine"), %(fine="yes")))).to be_fine
    end
  end

  describe "jumps" do
    it "takes the target from the words" do
      expect(first_bar(direction_xml(words_xml("D.S. al Fine"), %(dalsegno="segno1"))).jump)
        .to eq HeadMusic::Content::Jump.new(:dal_segno, to: :fine)
    end

    it "takes the kind from the sound when the words disagree" do
      expect(first_bar(direction_xml(words_xml("D.S. al Coda"), %(dacapo="yes"))).jump)
        .to eq HeadMusic::Content::Jump.new(:da_capo, to: :coda)
    end

    it "jumps with no target when the words name none" do
      expect(first_bar(direction_xml(words_xml("Da Capo"), %(dacapo="yes"))).jump).to eq HeadMusic::Content::Jump.new(:da_capo)
    end

    it "skips dacapo=\"no\"" do
      expect(first_bar(direction_xml(words_xml("Allegro"), %(dacapo="no"))).to_h).to eq({})
    end

    it "reads a <sound> written straight in the measure" do
      expect(first_bar(%(<sound dacapo="yes"/>)).jump).to eq HeadMusic::Content::Jump.new(:da_capo)
    end
  end

  it "lets a navigating sound decide over the words" do
    expect(first_bar(direction_xml(words_xml("Fine"), %(tocoda="coda1"))).to_h).to eq("to_coda" => true)
  end

  describe "with no navigating sound" do
    it "reads the signs and words" do
      bar = first_bar(direction_xml("<segno/>"), direction_xml(words_xml("To Coda")), direction_xml(words_xml("D.C. al Fine")))
      expect(bar.to_h).to eq("segno" => true, "to_coda" => true, "jump" => {"kind" => "da_capo", "to" => "fine"})
    end

    it "reads Fine from words beside a tempo" do
      expect(first_bar(direction_xml(words_xml("Fine"), %(tempo="96")))).to be_fine
    end

    it "skips other words" do
      expect(first_bar(direction_xml(words_xml("dolce"))).to_h).to eq({})
    end
  end

  it "reads a rehearsal mark at its bar" do
    flow = parse([whole_note, direction_xml("<rehearsal>B</rehearsal>") + whole_note])
    expect(flow.bars.map(&:rehearsal_mark)).to eq [nil, "B"]
  end

  describe "over several parts" do
    let(:flow) do
      parse(
        [direction_xml("<rehearsal>A</rehearsal>") + direction_xml("<segno/>", %(segno="s")) + whole_note],
        [direction_xml("<rehearsal>Z</rehearsal>") + whole_note + direction_xml(words_xml("Fine"), %(fine="yes"))]
      )
    end

    it "takes the first part's rehearsal mark and every part's flags" do
      expect(bar_markings(flow)).to eq [{"rehearsal_mark" => "A", "segno" => true, "fine" => true}]
    end
  end

  describe "round trips through the writer" do
    def round_trip(flow)
      HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(flow))
    end

    def played(flow)
      flow.performance_order.map { |played_bar| [played_bar.number, played_bar.pass] }
    end

    def two_part_navigation
      flow = HeadMusic::Content::Flow.new(name: "Navigation", key_signature: "C major", meter: "4/4")
      2.times do
        voice = flow.add_voice
        (1..6).each { |number| voice.place("#{number}:1", :whole, "C4") }
      end
      bars = flow.bars
      bars[0].rehearsal_mark = "Intro"
      bars[1].segno = true
      bars[1].starts_repeat = true
      bars[2].ends_repeat_after_num_plays = 3
      bars[2].to_coda = true
      bars[3].jump = HeadMusic::Content::Jump.new(:dal_segno)
      bars[3].fine = true
      bars[4].coda = true
      bars[4].rehearsal_mark = 5
      flow
    end

    {
      "NavigationFixtures.dal_segno_al_coda" => -> { NavigationFixtures.dal_segno_al_coda },
      "NavigationFixtures.da_capo_al_fine" => -> { NavigationFixtures.da_capo_al_fine },
      "LilyPondFixtures.dal_segno_al_coda" => -> { LilyPondFixtures.dal_segno_al_coda },
      "LilyPondFixtures.barline_styles" => -> { LilyPondFixtures.barline_styles },
      "Speed the Plough" => -> { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) },
      "navigation over two parts" => -> { two_part_navigation },
      **%i[suite single_flow_project trio clarinet_project mixed_ensemble].to_h do |name|
        ["LayoutFixtures.#{name}", -> { LayoutFixtures.public_send(name).flows.first }]
      end
    }.each do |name, build|
      context "with #{name}" do
        let(:flow) { instance_exec(&build) }
        let(:restored) { round_trip(flow) }

        it "keeps each bar's markings" do
          expect(bar_markings(restored)).to eq bar_markings(flow)
        end

        it "keeps the performance order" do
          expect(played(restored)).to eq played(flow)
        end
      end
    end
  end
end
