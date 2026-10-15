require "spec_helper"

describe HeadMusic::Notation::MusicXML::PartRoster do
  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  def round_trip(flow)
    parse(HeadMusic::Notation::MusicXML.render(flow))
  end

  def assignments(flow)
    flow.voices.map { |voice| voice.to_h["staff_assignments"] }
  end

  def grand_staff_attributes(extra = "")
    "<attributes><divisions>1</divisions><key><fifths>0</fifths></key><time><beats>4</beats><beat-type>4</beat-type></time>" \
      "<staves>2</staves><clef number=\"1\"><sign>G</sign><line>2</line></clef><clef number=\"2\"><sign>F</sign><line>4</line></clef>#{extra}</attributes>"
  end

  describe "a cross-staff piano" do
    let(:original) { LilyPondFixtures.cross_staff_piano }
    let(:flow) { round_trip(original) }

    it "braces two staves" do
      expect(flow.parts.first.staff_system.to_h).to eq("bracket" => "brace", "staves" => [{"clef" => "treble_clef"}, {"clef" => "bass_clef"}])
    end

    it "crosses each voice where the writer crossed it" do
      expect(assignments(flow)).to eq assignments(original)
    end

    it "reads every voice event" do
      expect(voice_event_strings(flow)).to eq voice_event_strings(original)
    end
  end

  describe "<part-symbol>" do
    def bracket_for(symbol)
      extra = symbol ? "<part-symbol>#{symbol}</part-symbol>" : ""
      attributes = "<attributes><divisions>1</divisions><staves>2</staves>#{extra}</attributes>"
      flow = parse(musicxml_measures(note_xml("C4", 4, "whole", staff: 1), attributes: attributes))
      flow.parts.first.staff_system.bracket
    end

    {"bracket" => :bracket, "square" => :bracket, "none" => :none, "brace" => :brace, "line" => :brace, nil => :brace}.each do |symbol, bracket|
      it "joins the staves with a #{bracket} for #{symbol.inspect}" do
        expect(bracket_for(symbol)).to eq bracket
      end
    end
  end

  it "brackets a choir's staves as the writer wrote them" do
    original = LilyPondFixtures.choir_on_two_staves
    expect(round_trip(original).parts.first.staff_system.to_h).to eq original.parts.first.staff_system.to_h
  end

  it "assigns each voice of a choir to its staff" do
    original = LilyPondFixtures.choir_on_two_staves
    expect(assignments(round_trip(original))).to eq assignments(original)
  end

  describe "a tie into a staff crossing" do
    let(:original) { LilyPondFixtures.tie_into_staff_crossing }
    let(:flow) { round_trip(original) }

    it "crosses at the barline the tied note crosses" do
      expect(assignments(flow)).to eq assignments(original)
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  describe "a staff change in the middle of a bar" do
    let(:flow) do
      parse(musicxml_measures(
        note_xml("C4", 2, "half", staff: 1) + note_xml("C3", 2, "half", staff: 2),
        note_xml("D3", 4, "whole", staff: 2),
        attributes: grand_staff_attributes
      ))
    end

    it "is skipped, the voice staying on its staff until the barline" do
      expect(assignments(flow)).to eq [[{"number" => 2, "staff" => 1}]]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  it "raises on a staff beyond the part's staves, naming the measure" do
    xml = musicxml_measures(note_xml("C4", 4, "whole"), [note_xml("C4", 4, "whole", staff: 2), {number: "2"}])
    expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, /<staff> of 2 is beyond the part's 1 staves \(measure 2 of part P1\)/)
  end

  [0, -1].each do |number|
    it "raises on a staff of #{number}, naming the measure" do
      xml = musicxml_measures(note_xml("C4", 4, "whole", staff: number), attributes: grand_staff_attributes)
      expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, /<staff> of #{number} is not positive \(measure 1 of part P1\)/)
    end
  end

  describe "clefs" do
    it "gives a one-staff part its clef" do
      expect(parse(musicxml_measures(note_xml("C4", 4, "whole"), attributes: opening_attributes(clef: %w[C 3]))).parts.first.staff_system.first_staff.clef.name_key)
        .to eq "alto_clef"
    end

    it "leaves a one-staff part with no clef to its fallback system" do
      expect(parse(musicxml_measures(note_xml("C4", 4, "whole"), attributes: opening_attributes(clef: nil))).parts.first.to_h).not_to have_key("staff_system")
    end

    it "reads a clef at a later barline as a clef change" do
      clef = "<attributes><clef><sign>F</sign><line>4</line></clef></attributes>"
      flow = parse(musicxml_measures(note_xml("C4", 4, "whole"), clef + note_xml("C3", 4, "whole")))
      expect(flow.parts.first.staff_system.first_staff.clef_changes.transform_values(&:name_key)).to eq(2 => "bass_clef")
    end

    it "skips a clef in the middle of a bar" do
      clef = "<attributes><clef><sign>F</sign><line>4</line></clef></attributes>"
      flow = parse(musicxml_measures(note_xml("C4", 4, "whole"), note_xml("C3", 2, "half") + clef + note_xml("D3", 2, "half")))
      expect(flow.parts.first.staff_system.first_staff.clef_changes).to be_empty
    end

    it "reads back the writer's clef changes on a grand staff" do
      original = LilyPondFixtures.cross_staff_piano.tap { |flow| flow.parts.first.staff_system.staves.last.change_clef(3, :tenor_clef) }
      expect(round_trip(original).parts.first.staff_system.staves.last.clef_changes.transform_values(&:name_key)).to eq(3 => "tenor_clef")
    end
  end
end
