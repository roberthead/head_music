require "spec_helper"

describe HeadMusic::Notation::LilyPond::TempoReader do
  def read(source)
    cursor = HeadMusic::Notation::LilyPond::TokenCursor.new(HeadMusic::Notation::LilyPond::Lexer.new("\\tempo #{source} c'4").tokens)
    command = cursor.advance
    tempo = described_class.new(cursor).read(command)
    [tempo, cursor.peek]
  end

  def summary(source)
    tempo, = read(source)
    [tempo.beat_value.to_s, tempo.beats_per_minute, tempo.text, tempo.metronome_mark?]
  end

  {
    %("Allegro" 4 = 120) => ["quarter", 120, "Allegro", true],
    "4 = 120" => ["quarter", 120, nil, true],
    "4. = 60" => ["dotted quarter", 60, nil, true],
    "2 = 100-120" => ["half", 100, nil, true],
    %("Andante") => ["quarter", 78, "Andante", false],
    %(\\markup { \\italic Allegro moderato }) => ["quarter", 116, "Allegro moderato", false],
    %(\\markup \\bold "Presto" 2 = 90) => ["half", 90, "Presto", true]
  }.each do |source, expected|
    it "reads \\tempo #{source}" do
      expect(summary(source)).to eq expected
    end
  end

  it "leaves the music after it unread" do
    expect(read("4 = 60").last.type).to eq :note
  end

  it "reads a \\tempo of blank text alone as nothing" do
    expect(read(%("")).first).to be_nil
  end

  it "raises for a \\tempo with neither text nor a metronome mark" do
    expect { read("") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /\\tempo expects text or a metronome mark/)
  end

  it "raises for no beats per minute" do
    expect { read("4 = 0") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /positive number of beats per minute/)
  end

  it "raises for a beat that is no duration" do
    expect { read("3 = 60") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unrecognized duration "3"/)
  end
end
