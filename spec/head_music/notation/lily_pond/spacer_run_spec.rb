require "spec_helper"

describe HeadMusic::Notation::LilyPond::SpacerRun do
  def mark(offset, token, onset: false)
    HeadMusic::Notation::LilyPond::TimedMarks::Mark.new(bar_number: 1, offset: offset, token: token, label: "dynamic #{token}", onset: onset)
  end

  def run(from, to, *marks)
    described_class.new(1, from, to, marks).to_s
  end

  it "fills the time with one spacer where no mark falls" do
    expect(run(0r, 1r)).to eq "s1"
  end

  it "ties spacers where no single value reaches" do
    expect(run(0r, Rational(5, 8))).to eq "s2 s8"
  end

  it "puts each mark on the first spacer where it falls" do
    expect(run(0r, 1r, mark(0r, "\\p"), mark(Rational(1, 2), "\\f"))).to eq "s2\\p s2\\f"
  end

  it "multiplies a spacer between note onsets that no value reaches" do
    expect(run(0r, Rational(1, 4), mark(Rational(1, 12), "\\p", onset: true), mark(0r, "\\f", onset: true)))
      .to eq "s1*1/12\\f s1*1/6\\p"
  end

  it "refuses a mark that no binary value reaches" do
    expect { run(0r, Rational(1, 4), mark(Rational(1, 12), "\\p")) }
      .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /cannot place the dynamic \\p/)
  end

  it "multiplies a spacer where no mark stands at either end" do
    expect(run(0r, Rational(1, 3))).to eq "s1*1/3"
  end
end
