require "spec_helper"

describe HeadMusic::Notation::Kern::MarkCodes do
  let(:voice) { HeadMusic::Content::Flow.new(meter: "4/4").add_voice }

  def read(field)
    remaining = field.dup
    [described_class.read!(remaining), remaining]
  end

  it "takes the marks out of the field it reads" do
    expect(read("4c'Tz")).to eq [{articulations: [:staccato], ornaments: [:trill], note_dynamic: :sfz}, "4c"]
  end

  it "reads the half-step forms as the ornament the whole-step form writes" do
    expect(read("tmw").first[:ornaments]).to eq %i[inverted_mordent mordent trill]
  end

  it "reads a heavy accent before the accent it contains" do
    expect(read("^^^").first[:articulations]).to eq %i[accent marcato]
  end

  described_class::ARTICULATIONS.each do |key, mark|
    it "writes the articulation #{key} as #{mark}, which reads back" do
      voice.place("1:1", :quarter, "C4").articulate(key.to_sym)
      expect(read(described_class.marks(voice.voice_events.first)).first[:articulations]).to eq [key.to_sym]
    end
  end

  described_class::ORNAMENTS.each do |key, mark|
    it "writes the ornament #{key} as #{mark}, which reads back" do
      voice.place("1:1", :quarter, "C4").embellish(key.to_sym)
      expect(read(described_class.marks(voice.voice_events.first)).first[:ornaments]).to eq [key.to_sym]
    end
  end

  it "writes no mark for a note dynamic that goes in **dynam" do
    voice.place("1:1", :quarter, "C4").note_dynamic = :sf
    expect(described_class.marks(voice.voice_events.first)).to eq ""
  end
end
