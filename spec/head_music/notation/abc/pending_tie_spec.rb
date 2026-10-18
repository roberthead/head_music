require "spec_helper"

describe HeadMusic::Notation::ABC::PendingTie do
  subject(:tie) { described_class.new }

  let(:pending_note) do
    HeadMusic::Notation::ABC::PendingNote.new(pitches: [HeadMusic::Rudiment::Pitch.get("E4")], length: "1", scale: 1)
  end

  it "is not open initially" do
    expect(tie).not_to be_open
  end

  it "rejects a terminator while open, on the terminator's line" do
    tie.open(3)
    expect { tie.reject(5) }.to raise_error(HeadMusic::Notation::ABC::ParseError) { |error| expect(error.line_number).to eq 5 }
  end

  it "rejects the end of the voice on the tie's line" do
    tie.open(3)
    expect { tie.reject(nil) }.to raise_error(HeadMusic::Notation::ABC::ParseError) { |error| expect(error.line_number).to eq 3 }
  end

  it "lets a terminator pass once closed" do
    tie.open(3)
    tie.close
    expect { tie.reject(5) }.not_to raise_error
  end

  it "ties the pending note to the same pitch" do
    expect { tie.ensure_ties(pending_note, [HeadMusic::Rudiment::Pitch.get("E4")]) }.not_to raise_error
  end

  it "refuses a different pitch on the tie's line" do
    tie.open(3)
    expect { tie.ensure_ties(pending_note, [HeadMusic::Rudiment::Pitch.get("D4")]) }
      .to raise_error(HeadMusic::Notation::ABC::ParseError, /same pitch/) { |error| expect(error.line_number).to eq 3 }
  end
end
