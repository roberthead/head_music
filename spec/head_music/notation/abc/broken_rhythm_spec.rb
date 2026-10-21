require "spec_helper"

describe HeadMusic::Notation::ABC::BrokenRhythm do
  subject(:broken_rhythm) { described_class.new }

  let(:left_note) do
    HeadMusic::Notation::ABC::PendingNote.new(pitches: [HeadMusic::Rudiment::Pitch.get("C4")], length: "1", scale: Rational(1))
  end

  it "dots the left note of > and halves the right" do
    left = broken_rhythm.break(left_note, :>, 1)
    expect([left.scale, broken_rhythm.take_scale]).to eq [Rational(3, 2), Rational(1, 2)]
  end

  it "halves the left note of < and dots the right" do
    left = broken_rhythm.break(left_note, :<, 1)
    expect([left.scale, broken_rhythm.take_scale]).to eq [Rational(1, 2), Rational(3, 2)]
  end

  it "scales a note no mark awaits by one" do
    expect(broken_rhythm.take_scale).to eq 1
  end

  it "awaits the right note until its scale is taken" do
    broken_rhythm.break(left_note, :>, 1)
    awaiting = broken_rhythm.awaiting_note?
    broken_rhythm.take_scale
    expect([awaiting, broken_rhythm.awaiting_note?]).to eq [true, false]
  end

  it "refuses a mark with no left note, on the mark's line" do
    expect { broken_rhythm.break(nil, :>, 4) }
      .to raise_error(HeadMusic::Notation::ABC::ParseError, /between two notes/) { |error| expect(error.line_number).to eq 4 }
  end

  it "refuses a mark whose left note is still the right note of another" do
    broken_rhythm.break(left_note, :>, 1)
    expect { broken_rhythm.break(left_note, :<, 2) }
      .to raise_error(HeadMusic::Notation::ABC::ParseError, /between two notes/) { |error| expect(error.line_number).to eq 2 }
  end

  it "refuses to end while the right note is awaited, on the mark's line" do
    broken_rhythm.break(left_note, :>, 3)
    expect { broken_rhythm.ensure_not_awaiting_note(nil) }
      .to raise_error(HeadMusic::Notation::ABC::ParseError) { |error| expect(error.line_number).to eq 3 }
  end
end
