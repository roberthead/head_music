require "spec_helper"

describe HeadMusic::Notation::MusicXML::ConcertTransposition do
  subject(:transposition) { described_class.new }

  def step(diatonic, chromatic, octaves = 0)
    described_class::Step.new(diatonic, chromatic, octaves)
  end

  def pitch(name)
    HeadMusic::Rudiment::Pitch.get(name)
  end

  def parse_written(project)
    HeadMusic::Notation::MusicXML.parse(project.add_layout(concert_pitch: false).to_musicxml)
  end

  def pitches(flow)
    flow.voices.map { |voice| voice.pitches.map(&:to_s) }
  end

  it "leaves a pitch alone with no transposition" do
    expect(transposition.concert(pitch("D4"), 1).to_s).to eq "D4"
  end

  it "sounds a B-flat clarinet's written D4 as C4" do
    transposition.change(nil, step(-1, -2))
    expect(transposition.concert(pitch("D4"), 1).to_s).to eq "C4"
  end

  it "sounds a bass clarinet's written C5 as B-flat 3" do
    transposition.change(nil, step(-1, -2, -1))
    expect(transposition.concert(pitch("C5"), 1).to_s).to eq "B♭3"
  end

  it "keeps a numbered transposition to its staff" do
    transposition.change(2, step(0, 0, -1))
    expect([transposition.concert(pitch("C4"), 1), transposition.concert(pitch("C4"), 2)].map(&:to_s)).to eq %w[C4 C3]
  end

  it "moves a key round the circle of fifths" do
    transposition.change(nil, step(-1, -2))
    expect(transposition.concert_fifths(2)).to eq 0
  end

  describe "reading a transposed document" do
    it "reads the trio's pitches at concert pitch" do
      project = LayoutFixtures.trio
      expect(pitches(parse_written(project))).to eq pitches(project.flows.first)
    end

    it "reads the trio's key at concert pitch" do
      expect(parse_written(LayoutFixtures.trio).key_signature.to_s).to eq "no sharps or flats"
    end

    it "reads an octave transposer at concert pitch" do
      project = LayoutFixtures.clarinet_project(instrument: "bass_clarinet")
      expect(pitches(parse_written(project))).to eq pitches(project.flows.first)
    end

    it "returns to concert pitch after a change to an instrument in C" do
      project = LayoutFixtures.clarinet_project
      project.flows.first.parts.first.change_instrument(3, "flute")
      expect(pitches(parse_written(project))).to eq [%w[C4 D4 E4 F4]]
    end

    it "transposes grace notes" do
      attributes = opening_attributes(extra: "<transpose><diatonic>-1</diatonic><chromatic>-2</chromatic></transpose>")
      xml = musicxml_measures("<note><grace/>#{pitch_xml("F#4")}<type>eighth</type></note>" + note_xml("D4", 4, "whole"), attributes: attributes)
      grace = HeadMusic::Notation::MusicXML.parse(xml).voices.first.voice_events.first.grace_notes.first
      expect(grace.pitches.map(&:to_s)).to eq ["E4"]
    end

    it "transposes one staff alone by a numbered <transpose>" do
      attributes = opening_attributes(extra: "<staves>2</staves><transpose number=\"2\"><diatonic>0</diatonic><chromatic>0</chromatic>" \
        "<octave-change>-1</octave-change></transpose>")
      xml = musicxml_measures(note_xml("C4", 4, "whole", voice: "1", staff: 1) + backup_xml(4) + note_xml("C4", 4, "whole", voice: "2", staff: 2), attributes: attributes)
      expect(pitches(HeadMusic::Notation::MusicXML.parse(xml))).to eq [%w[C4], %w[C3]]
    end
  end
end
