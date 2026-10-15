require "spec_helper"

describe HeadMusic::Notation::MusicXML::PitchReader do
  def parse_pitch(pitch, attributes: opening_attributes)
    note = "<note>#{pitch}<duration>4</duration><type>whole</type></note>"
    HeadMusic::Notation::MusicXML.parse(musicxml_measures(note, attributes: attributes))
  end

  let(:unsupported) { HeadMusic::Notation::MusicXML::UnsupportedFeatureError }

  it "reads the catalog's highest octave" do
    expect(parse_pitch("<pitch><step>B</step><octave>9</octave></pitch>").voices.first.pitches.map(&:to_s)).to eq ["B9"]
  end

  it "reads the catalog's lowest octave" do
    expect(parse_pitch("<pitch><step>C</step><alter>-1</alter><octave>-1</octave></pitch>").voices.first.pitches.map(&:to_s)).to eq ["C♭-1"]
  end

  {
    "an octave above the catalog" => "<pitch><step>C</step><octave>10</octave></pitch>",
    "an octave below the catalog" => "<pitch><step>C</step><octave>-50</octave></pitch>",
    "an alteration beyond a double sharp" => "<pitch><step>C</step><alter>99</alter><octave>4</octave></pitch>"
  }.each do |description, pitch|
    it "refuses #{description}, naming the measure" do
      expect { parse_pitch(pitch) }.to raise_error(unsupported, /has no spelling \(measure 1 of part P1\)/)
    end
  end

  it "refuses a transposition that takes a pitch out of the catalog, naming the measure" do
    attributes = opening_attributes(extra: "<transpose><diatonic>0</diatonic><chromatic>0</chromatic><octave-change>3</octave-change></transpose>")
    expect { parse_pitch("<pitch><step>C</step><octave>8</octave></pitch>", attributes: attributes) }
      .to raise_error(unsupported, /has no spelling \(measure 1 of part P1\)/)
  end
end
