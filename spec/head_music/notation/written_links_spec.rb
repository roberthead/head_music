require "spec_helper"

describe HeadMusic::Notation::WrittenLinks do
  let(:flow) { HeadMusic::Content::Flow.new(meter: "2/4") }
  let(:voice) { flow.add_voice }
  let(:links) { described_class.for(HeadMusic::Notation::BarSplitter.segments(voice.voice_events)) }

  def summary(links)
    links.map { |link| [link.bar_number, link.offset, link.index, link.written_fraction] }
  end

  def place_in_turn(*values)
    values.each { |value| voice.place(voice.next_position, value, "C4") }
  end

  it "lists a note split at a barline once in each bar it sounds in" do
    place_in_turn(:quarter, :half, :quarter)
    quarter = Rational(1, 4)
    expect(summary(links)).to eq [[1, 0, 0, quarter], [1, quarter, 0, quarter], [2, 0, 0, quarter], [2, quarter, 0, quarter]]
  end

  it "steps through a tied chain link by link" do
    place_in_turn(HeadMusic::Rudiment::RhythmicValue.new(:eighth, tied_value: HeadMusic::Rudiment::RhythmicValue.get(:sixteenth)))
    expect(summary(links)).to eq [[1, 0, 0, Rational(1, 8)], [1, Rational(1, 8), 1, Rational(1, 16)]]
  end

  it "steps through triplets by what they sound" do
    place_in_turn(*Array.new(3, HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "3:2")))
    expect(links.map(&:offset)).to eq [0, Rational(1, 12), Rational(1, 6)]
  end

  context "with a piece no note value can write" do
    let(:flow) { HeadMusic::Content::Flow.new(meter: "12/1") }

    before do
      maxima = HeadMusic::Rudiment::RhythmicValue.get(:maxima)
      place_in_turn(:whole, HeadMusic::Rudiment::RhythmicValue.new(:maxima, tied_value: maxima))
    end

    it "raises the given error" do
      segments = HeadMusic::Notation::BarSplitter.segments(voice.voice_events)
      expect { described_class.for(segments, error_class: HeadMusic::Notation::Kern::RenderError) }
        .to raise_error(HeadMusic::Notation::Kern::RenderError)
    end
  end
end
