require "spec_helper"

describe HeadMusic::Notation::LilyPond::SpanPairing do
  subject(:pairing) { described_class.new }

  let(:voice) { MarkingFixtures.four_quarters.voices.first }
  let(:span_mark_class) { HeadMusic::Notation::LilyPond::MarkReader::SpanMark }

  def mark(opening, kind: :slur, id: nil, from_grace: false)
    span_mark_class.new(kind: kind, opening: opening, id: id, from_grace: from_grace)
  end

  def apply(index, *marks)
    pairing.apply(voice.voice_events[index], marks)
  end

  def spans
    voice.spans.map { |span| [span.kind, voice.voice_events.index { |event| event.position == span.from }, voice.voice_events.index { |event| event.position == span.to }] }
  end

  it "pairs an open with the next close of its kind and name" do
    apply(0, mark(true))
    apply(2, mark(false))
    expect(spans).to eq [[:slur, 0, 2]]
  end

  it "ignores an open while one of its kind and name is open" do
    apply(0, mark(true))
    apply(1, mark(true))
    apply(2, mark(false))
    apply(3, mark(false))
    expect(spans).to eq [[:slur, 0, 2]]
  end

  it "pairs differently named marks apart" do
    apply(0, mark(true))
    apply(1, mark(true, id: "1"))
    apply(2, mark(false))
    apply(3, mark(false, id: "1"))
    expect(spans).to contain_exactly([:slur, 0, 2], [:slur, 1, 3])
  end

  it "drops a close with none open" do
    apply(1, mark(false, kind: :phrase))
    expect(spans).to be_empty
  end

  it "drops a span that opens and closes on one note unless it starts from grace notes" do
    apply(1, mark(true), mark(false))
    expect(spans).to be_empty
  end
end
