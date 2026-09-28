require "spec_helper"

describe HeadMusic::Content::Span do
  let(:flow) { HeadMusic::Content::Flow.new }

  def span(kind = :slur, from: "1:1", to: "1:3")
    described_class.new(flow, kind, from: from, to: to)
  end

  it "coerces its positions" do
    expect([span.from.to_s, span.to.to_s]).to eq %w[1:1:000 1:3:000]
  end

  it "answers its kind as a symbol" do
    expect(span(:phrasing_slur).kind).to eq :phrase
  end

  it "refuses an unknown kind" do
    expect { span(:bogus) }.to raise_error(ArgumentError, "unknown span kind: :bogus")
  end

  it "refuses an end at its start" do
    expect { span(from: "1:1", to: "1:1") }.to raise_error(ArgumentError, /must end after it starts/)
  end

  it "refuses an end before its start" do
    expect { span(from: "1:3", to: "1:1") }.to raise_error(ArgumentError, /must end after it starts/)
  end

  it "refuses a position from another flow" do
    other = HeadMusic::Content::Position.new(HeadMusic::Content::Flow.new, "1:1")
    expect { span(from: other) }.to raise_error(ArgumentError, "position belongs to a different flow")
  end

  it "orders by start, then end, then kind" do
    spans = [span(:phrase, to: "1:3"), span(to: "1:4"), span(from: "1:2"), span(to: "1:3")]
    expect(spans.sort.map(&:to_s)).to eq [
      "slur from 1:1:000 to 1:3:000", "phrase from 1:1:000 to 1:3:000",
      "slur from 1:1:000 to 1:4:000", "slur from 1:2:000 to 1:3:000"
    ]
  end

  it "equals a span of the same kind and positions" do
    same = described_class.new(flow, "slur", from: "1:1:000", to: "1:3:000")
    expect(span).to eq same
  end

  it "writes its kind and positions" do
    expect(span.to_h).to eq("kind" => "slur", "from" => "1:1:000", "to" => "1:3:000")
  end
end
