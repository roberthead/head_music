require "spec_helper"

describe HeadMusic::Notation::LilyPond::TempoWriter do
  def tempo(...)
    HeadMusic::Rudiment::Tempo.new(...)
  end

  describe ".token" do
    {
      "text and a metronome mark" => [["dotted quarter", 60, {text: "Andante"}], %(\\tempo "Andante" 4. = 60)],
      "a metronome mark" => [["dotted quarter", 60, {}], "\\tempo 4. = 60"],
      "text alone" => [["quarter", 78, {text: "Andante", metronome_mark: false}], %(\\tempo "Andante")],
      "no number written and no text" => [["half", 60, {metronome_mark: false}], "\\tempo 2 = 60"],
      "text to escape" => [["quarter", 60, {text: %(Con "moto" \\ x)}], %(\\tempo "Con \\"moto\\" \\\\ x" 4 = 60)]
    }.each do |description, ((beat, count, options), written)|
      it "writes #{description}" do
        expect(described_class.token(tempo(beat, count, **options))).to eq written
      end
    end
  end

  it "writes words as italic markup above the staff, escaped" do
    expect(described_class.text_mark(%(poco "rit."))).to eq %(^\\markup \\italic "poco \\"rit.\\"")
  end

  describe ".problem" do
    it "names a fractional tempo" do
      expect(described_class.problem(tempo("quarter", 60.5))).to eq "the fractional tempo of 60.5 beats per minute"
    end

    it "lets a fractional number go unwritten behind text" do
      expect(described_class.problem(tempo("quarter", 60.5, text: "Lento", metronome_mark: false))).to be_nil
    end

    it "names a tied beat" do
      beat = HeadMusic::Rudiment::RhythmicValue.new(:quarter, tied_value: HeadMusic::Rudiment::RhythmicValue.new(:eighth))
      expect(described_class.problem(tempo(beat, 60))).to start_with "the tempo beat of"
    end

    it "has nothing to say of a whole number of beats" do
      expect(described_class.problem(tempo("half", 60))).to be_nil
    end
  end
end
