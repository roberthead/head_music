require "spec_helper"

describe HeadMusic::Notation::MusicXML::Writer do
  let(:document) { parse_musicxml(described_class.new(TupletFixtures.grace_notes_before_downbeat).to_s) }

  def notes(measure)
    REXML::XPath.match(document, "//part/measure[@number='#{measure}']/note")
  end

  def grace?(note)
    !note.elements["grace"].nil?
  end

  it "writes a slashed grace note before its downbeat" do
    grace, main = notes(2)
    expect([grace.elements["grace"].attributes["slash"], grace.elements["type"].text, grace?(main)]).to eq ["yes", "eighth", false]
  end

  it "writes an unslashed grace note with no slash" do
    grace = notes(3).first
    expect(grace.elements["grace"].attributes.to_h).to be_empty
  end

  it "writes a grace note in element order, with no duration or beams" do
    grace = notes(2).first
    expect(xpath_names(grace, "*")).to eq %w[grace pitch type]
  end

  it "writes a grace chord as a lead note and a chord member" do
    graces = notes(1).select { |note| grace?(note) }.first(2)
    expect(graces.map { |note| [xpath_names(note, "*").first(2), note.elements["pitch/step"].text] })
      .to eq [[%w[grace pitch], "A"], [%w[grace chord], "C"]]
  end

  it "keeps a grace note's articulation" do
    grace = notes(1).reverse.find { |note| grace?(note) }
    expect(xpath_names(grace, "notations/articulations/*")).to eq %w[staccato]
  end

  it "ties a grace note into its main note" do
    _first, tied, main = notes(3)
    expect([REXML::XPath.match(tied, "tie").map { |tie| tie.attributes["type"] }, REXML::XPath.match(main, "tie").map { |tie| tie.attributes["type"] }])
      .to eq [%w[start], %w[stop]]
  end

  it "draws the tie on both notes" do
    _first, tied, main = notes(3)
    expect([tied, main].map { |note| note.elements["notations/tied"].attributes["type"] }).to eq %w[start stop]
  end

  it "starts a slur from the grace notes on the first of them and stops it on the main note" do
    first, _tied, main = notes(3)
    slurs = [first, main].map { |note| %w[type number].map { |name| note.elements["notations/slur"].attributes[name] } }
    expect(slurs).to eq [%w[start 1], %w[stop 1]]
  end

  it "leaves the measure's durations unchanged" do
    expect(notes(1).reject { |note| grace?(note) }.sum { |note| note.elements["duration"].text.to_i }).to eq 4
  end

  it "writes grace notes in a pickup bar" do
    pickup = parse_musicxml(described_class.new(TupletFixtures.grace_notes_in_pickup).to_s)
    expect(xpath_count(pickup, "//measure[@number='0']/note[grace]")).to eq 1
  end

  it "writes the grace notes on the first piece of a note split at the barline" do
    flow = TupletFixtures.tuplet_crossing_barline
    flow.voices.first.voice_events[2].add_grace_note("C4", :sixteenth)
    split = parse_musicxml(described_class.new(flow).to_s)
    expect([1, 2].map { |measure| xpath_count(split, "//measure[@number='#{measure}']/note[grace]") }).to eq [1, 0]
  end

  it "ties only the pitches a tied grace note shares with the note after it" do
    flow = TupletFixtures.flow("Tied Chord")
    voice = TupletFixtures.fill(flow.add_voice, [[:whole, %w[C4 E4]]])
    voice.voice_events.first.add_grace_note(%w[C4 D4], :eighth, tied: true)
    tied = parse_musicxml(described_class.new(flow).to_s)
    expect(xpath_texts(tied, "//note[tie]/pitch/step")).to eq %w[C C]
  end

  it "refuses an unpitched grace note" do
    flow = TupletFixtures.flow("Drum")
    voice = TupletFixtures.fill(flow.add_voice, [[:whole, "C4"]])
    voice.voice_events.first.add_grace_note("snare drum", :eighth)
    expect { described_class.new(flow).to_s }.to raise_error(HeadMusic::Notation::MusicXML::RenderError, /unpitched/)
  end
end
