require "spec_helper"

describe HeadMusic::Notation::MusicXML::SlurNumbers do
  let(:flow) { MarkingFixtures.four_quarters }
  let(:voice) { flow.voices.first }

  def numbers_at(*positions)
    numbers = described_class.new(voice.part)
    events = positions.map { |position| voice.voice_events.find { |event| event.position == HeadMusic::Content::Position.new(flow, position) } }
    events.map { |event| [numbers.starts_at(event), numbers.stops_at(event)] }
  end

  it "numbers a lone slur 1" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    expect(numbers_at("1:1", "1:3")).to eq [[[1], []], [[], [1]]]
  end

  it "numbers a phrase as a slur" do
    voice.add_span(:phrase, from: "1:1", to: "2:1")
    expect(numbers_at("1:1", "2:1")).to eq [[[1], []], [[], [1]]]
  end

  it "gives slurs open at once their own numbers" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    voice.add_span(:slur, from: "1:2", to: "1:4")
    expect(numbers_at("1:2", "1:4")).to eq [[[2], []], [[], [2]]]
  end

  it "reuses a number where one slur ends and the next begins" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    voice.add_span(:slur, from: "1:3", to: "2:1")
    expect(numbers_at("1:3")).to eq [[[1], [1]]]
  end

  it "numbers across the voices of a part" do
    flow = MarkingFixtures.spanned_piano
    numbers = described_class.new(flow.parts.first)
    expect(flow.voices.map { |each_voice| numbers.starts_at(each_voice.voice_events.first) }).to eq [[1], [2]]
  end

  it "refuses a seventeenth slur open at once" do
    flow = HeadMusic::Content::Flow.new(meter: "4/4")
    part = flow.add_part(instrument: "piano")
    17.times { part.add_voice.tap { |each_voice| %w[1:1 1:3].each { |position| each_voice.place(position, :half, "C4") } }.add_span(:slur, from: "1:1", to: "1:3") }
    expect { described_class.new(part) }.to raise_error(HeadMusic::Notation::MusicXML::RenderError, /more than 16 slurs/)
  end
end
