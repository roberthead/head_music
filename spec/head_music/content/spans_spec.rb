require "spec_helper"

describe HeadMusic::Content::Spans do
  subject(:spans) { described_class.new }

  let(:flow) { HeadMusic::Content::Flow.new }

  def span(kind = :slur, from: "1:1", to: "1:3")
    HeadMusic::Content::Span.new(flow, kind, from: from, to: to)
  end

  it "keeps its spans in order" do
    [span(from: "1:2"), span(:phrase), span].each { |each_span| spans.add(each_span) }
    expect(spans.map(&:to_s)).to eq ["slur from 1:1:000 to 1:3:000", "phrase from 1:1:000 to 1:3:000", "slur from 1:2:000 to 1:3:000"]
  end

  it "keeps spans of one kind that overlap" do
    spans.add(span(to: "1:3"))
    spans.add(span(from: "1:2", to: "1:4"))
    expect(spans.length).to eq 2
  end

  it "refuses the same span twice" do
    spans.add(span)
    expect { spans.add(span) }.to raise_error(ArgumentError, "the slur from 1:1:000 to 1:3:000 is already there")
  end

  it "answers a copy of its spans" do
    spans.add(span)
    spans.to_a.clear
    expect(spans.length).to eq 1
  end
end
