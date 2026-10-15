require "spec_helper"

describe HeadMusic::Notation::MusicXML::AttributesReader do
  def parse_attributes(inner)
    HeadMusic::Notation::MusicXML.parse(musicxml_measures(note_xml("C4", 4, "whole"), attributes: "<attributes>#{inner}</attributes>"))
  end

  def time_xml(beats, beat_type)
    "<divisions>1</divisions><time>#{beats}#{beat_type}</time>"
  end

  let(:parse_error) { HeadMusic::Notation::MusicXML::ParseError }
  let(:unsupported) { HeadMusic::Notation::MusicXML::UnsupportedFeatureError }

  it "refuses an empty <divisions>, naming the measure" do
    expect { parse_attributes("<divisions/>") }.to raise_error(parse_error, /<divisions> must be positive \(measure 1 of part P1\)/)
  end

  it "refuses an empty <staves>, naming the measure" do
    expect { parse_attributes("<divisions>1</divisions><staves/>") }
      .to raise_error(parse_error, /<staves> must be positive \(measure 1 of part P1\)/)
  end

  describe "a <time>" do
    it "reads a meter" do
      expect(parse_attributes(time_xml("<beats>3</beats>", "<beat-type>2</beat-type>")).meter_at(1).to_s).to eq "3/2"
    end

    it "states no meter with neither number, as under <senza-misura/>" do
      expect(parse_attributes("<divisions>1</divisions><time><senza-misura/></time>").meter_at(1).to_s).to eq "4/4"
    end

    {
      "a zero beat type" => ["<beats>4</beats>", "<beat-type>0</beat-type>", "<beat-type>"],
      "a negative beat type" => ["<beats>4</beats>", "<beat-type>-4</beat-type>", "<beat-type>"],
      "zero beats" => ["<beats>0</beats>", "<beat-type>4</beat-type>", "<beats>"],
      "negative beats" => ["<beats>-4</beats>", "<beat-type>4</beat-type>", "<beats>"],
      "an empty beat type" => ["<beats>4</beats>", "<beat-type/>", "<beat-type>"],
      "a missing beat type" => ["<beats>4</beats>", "", "<beat-type>"]
    }.each do |description, (beats, beat_type, label)|
      it "refuses #{description}, naming the measure" do
        expect { parse_attributes(time_xml(beats, beat_type)) }
          .to raise_error(parse_error, /#{label} must be positive \(measure 1 of part P1\)/)
      end
    end

    it "refuses a beat type that names no note value, such as 3/3" do
      expect { parse_attributes(time_xml("<beats>3</beats>", "<beat-type>3</beat-type>")) }
        .to raise_error(unsupported, %r{The meter 3/3 is not supported \(measure 1 of part P1\)})
    end

    it "refuses a beat type too short for any note value" do
      expect { parse_attributes(time_xml("<beats>4</beats>", "<beat-type>1024</beat-type>")) }
        .to raise_error(unsupported, %r{The meter 4/1024 is not supported})
    end
  end
end
