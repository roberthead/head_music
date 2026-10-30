require "spec_helper"

describe HeadMusic::MIDI::BarPieces do
  let(:flow) { HeadMusic::Content::Flow.new }
  let(:voice) { flow.add_voice }

  def pieces(position, value, from: 0, to: nil)
    voice_event = voice.place(position, value, "C4")
    described_class.of(voice_event, from, to || voice_event.rhythmic_duration.fraction)
  end

  def summary(list)
    list.map { |piece| [piece.bar_number, piece.from, piece.to, piece.joins_previous, piece.continues] }
  end

  it "keeps a note within its bar whole" do
    expect(summary(pieces("1:2", :quarter))).to eq [[1, Rational(1, 4), Rational(1, 2), false, false]]
  end

  it "cuts a note over the barline, the first piece continuing and the second joining it" do
    expect(summary(pieces("1:3", :whole))).to eq [
      [1, Rational(1, 2), 1, false, true],
      [2, 0, Rational(1, 2), true, false]
    ]
  end

  it "cuts a note over several barlines" do
    expect(summary(pieces("1:1", "whole tied to whole tied to quarter")).map(&:first)).to eq [1, 2, 3]
  end

  it "starts a piece in the bar it falls in, though its note starts earlier" do
    expect(summary(pieces("1:3", :whole, from: Rational(3, 4)))).to eq [[2, Rational(1, 4), Rational(1, 2), false, false]]
  end

  it "ends a piece at a barline without continuing" do
    expect(summary(pieces("1:3", :half))).to eq [[1, Rational(1, 2), 1, false, false]]
  end

  it "answers nothing for an empty interval" do
    expect(pieces("1:1", :quarter, from: Rational(1, 4), to: Rational(1, 4))).to be_empty
  end

  it "measures each bar by its own meter" do
    flow.change_meter(2, "3/8")
    expect(summary(pieces("1:4", :half)).map { |piece| piece[1, 2] }).to eq [[Rational(3, 4), 1], [0, Rational(1, 4)]]
  end
end
