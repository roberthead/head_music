require "spec_helper"

describe HeadMusic::Notation::MusicXML::BarMap do
  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  let(:whole_c) { note_xml("C4", 4, "whole") }

  describe "a pickup" do
    let(:flow) { parse(musicxml_measures([note_xml("G4", 1, "quarter"), {number: "0", implicit: true}], whole_c)) }

    it "is bar 0" do
      expect(flow.earliest_bar_number).to eq 0
    end

    it "is right-aligned in its bar" do
      expect(voice_event_strings(flow).first.first(2)).to eq ["dotted half rest at 0:1:000", "quarter G4 at 0:4:000"]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  it "right-aligns a short first measure that is not implicit, as bar 1" do
    flow = parse(musicxml_measures(note_xml("G4", 1, "quarter"), whole_c))
    expect(voice_event_strings(flow).first.first(2)).to eq ["dotted half rest at 1:1:000", "quarter G4 at 1:4:000"]
  end

  it "reads a short final bar" do
    flow = parse(musicxml_measures(whole_c, note_xml("D4", 3, "half", dots: 1)))
    expect(flow.voices.first.last_voice_event.to_s).to eq "dotted half D4 at 2:1:000"
  end

  describe "a measure split at a repeat" do
    let(:flow) do
      parse(musicxml_measures(whole_c, note_xml("D4", 2, "half"), [note_xml("E4", 2, "half"), {number: "X1", implicit: true}], whole_c))
    end

    it "joins the two halves into one bar" do
      expect(voice_event_strings(flow).first).to eq ["whole C4 at 1:1:000", "half D4 at 2:1:000", "half E4 at 2:3:000", "whole C4 at 3:1:000"]
    end

    it "keeps the music whole" do
      expect_music_whole(flow)
    end
  end

  describe "a measure split at a repeat, its second half not marked implicit, as music21 and others export one" do
    let(:flow) do
      repeat = %(<barline location="right"><bar-style>light-heavy</bar-style><repeat direction="backward"/></barline>)
      parse(musicxml_measures(whole_c, note_xml("D4", 3, "half", dots: 1) + repeat, note_xml("E4", 1, "quarter"), whole_c))
    end

    it "joins the two halves into one bar" do
      expect(voice_event_strings(flow).first).to eq ["whole C4 at 1:1:000", "dotted half D4 at 2:1:000", "quarter E4 at 2:4:000", "whole C4 at 3:1:000"]
    end

    it "ends the repeat inside the bar it closes" do
      expect(flow.bars(3).map(&:ends_repeat_after_num_plays)).to eq [nil, 2, nil]
    end
  end

  it "joins halves that restate the meter" do
    restated = "<attributes><time><beats>4</beats><beat-type>4</beat-type></time></attributes>" + note_xml("E4", 2, "half")
    flow = parse(musicxml_measures(whole_c, note_xml("D4", 2, "half"), restated, whole_c))
    expect(voice_event_strings(flow).first[2]).to eq "half E4 at 2:3:000"
  end

  it "refuses a short measure whose follower changes the meter, unless the follower is implicit" do
    three_four = "<attributes><time><beats>3</beats><beat-type>4</beat-type></time></attributes>" + note_xml("E4", 1, "quarter")
    xml = musicxml_measures(whole_c, note_xml("D4", 3, "half", dots: 1), three_four, note_xml("F4", 3, "half", dots: 1))
    expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /shorter than its 4\/4 bar.*\(measure 2 of part P1\)/)
  end

  describe "an implicit second half that changes the meter" do
    let(:flow) do
      three_four = "<attributes><time><beats>3</beats><beat-type>4</beat-type></time></attributes>" + note_xml("E4", 2, "half")
      parse(musicxml_measures(whole_c, note_xml("D4", 2, "half"), [three_four, {number: "X1", implicit: true}], note_xml("F4", 3, "half", dots: 1)))
    end

    it "joins the two halves into one bar of the meter before" do
      expect(voice_event_strings(flow).first).to eq ["whole C4 at 1:1:000", "half D4 at 2:1:000", "half E4 at 2:3:000", "dotted half F4 at 3:1:000"]
    end

    it "changes the meter at the next downbeat" do
      expect((1..3).map { |bar| flow.meter_at(bar).to_s }).to eq %w[4/4 4/4 3/4]
    end
  end

  it "refuses an overfull measure, naming it" do
    xml = musicxml_measures(whole_c, [whole_c + note_xml("D4", 1, "quarter"), {number: "2"}])
    expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /longer than its 4\/4 bar \(measure 2 of part P1\)/)
  end

  it "refuses a measure overfull by less than another part's division, naming its part" do
    fine = [note_xml("C4", 16, "whole") + note_xml("D4", 1, "16th"), note_xml("C4", 16, "whole")]
    coarse = [note_xml("C3", 4, "whole"), note_xml("C3", 4, "whole")]
    xml = musicxml_document(fine, coarse).sub("<divisions>1</divisions>", "<divisions>4</divisions>")
    expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /longer than its 4\/4 bar \(measure 1 of part P1\)/)
  end

  it "refuses a short measure in the middle of the piece, naming it" do
    xml = musicxml_measures(whole_c, note_xml("D4", 2, "half"), whole_c)
    expect { parse(xml) }.to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /shorter than its 4\/4 bar.*\(measure 2 of part P1\)/)
  end

  it "takes a whole-measure rest as filling its bar, not as reaching" do
    flow = parse(musicxml_measures(whole_c, measure_rest_xml(4), note_xml("E4", 2, "half")))
    expect(voice_event_strings(flow).first).to eq ["whole C4 at 1:1:000", "whole rest at 2:1:000", "half E4 at 3:1:000"]
  end

  it "takes a rest as long as the meter as a whole-measure rest, whatever its type" do
    flow = parse(musicxml_measures(whole_c, rest_xml(4, "half"), note_xml("E4", 4, "whole")))
    expect(voice_event_strings(flow).first[1]).to eq "whole rest at 2:1:000"
  end

  it "aligns a part's measures with a longer part's" do
    flow = parse(musicxml_document([note_xml("G4", 1, "quarter"), whole_c], [rest_xml(1, "quarter"), note_xml("C3", 4, "whole")]))
    expect(voice_event_strings(flow).map(&:first)).to eq ["dotted half rest at 1:1:000", "dotted half rest at 1:1:000"]
  end

  it "applies a change of divisions from its point onward" do
    later = "<attributes><divisions>2</divisions></attributes>" + note_xml("D4", 2, "quarter") + note_xml("E4", 6, "half", dots: 1)
    flow = parse(musicxml_measures(whole_c, later))
    expect(voice_event_strings(flow).first).to eq ["whole C4 at 1:1:000", "quarter D4 at 2:1:000", "dotted half E4 at 2:2:000"]
  end
end
