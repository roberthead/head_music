require "spec_helper"

describe HeadMusic::Notation::MusicXML::SlurNumbers do
  let(:flow) { MarkingFixtures.four_quarters }
  let(:voice) { flow.voices.first }

  def slur_numbers(flow)
    described_class.new(flow.parts.first, HeadMusic::Notation::MusicXML::RenderPlan.new(flow))
  end

  def event_at(voice, position)
    voice.voice_events.find { |event| event.position == HeadMusic::Content::Position.new(voice.flow, position) }
  end

  def numbers_at(*positions)
    numbers = slur_numbers(flow)
    positions.map { |position| [numbers.starts_at(event_at(voice, position)), numbers.stops_at(event_at(voice, position))] }
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

  it "reuses a number where one slur ends and the next begins on one note" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    voice.add_span(:slur, from: "1:3", to: "2:1")
    expect(numbers_at("1:3")).to eq [[[1], [1]]]
  end

  it "gives a slur beginning on a tied note where another ends its own number, since it starts first" do
    flow = MarkingFixtures.touching_slurs_on_tied_note
    tied = event_at(flow.voices.first, "1:4")
    numbers = slur_numbers(flow)
    expect([numbers.starts_at(tied), numbers.stops_at(tied)]).to eq [[2], [1]]
  end

  it "numbers across the voices of a part" do
    flow = MarkingFixtures.spanned_piano
    numbers = slur_numbers(flow)
    expect(flow.voices.map { |each_voice| numbers.starts_at(each_voice.voice_events.first) }).to eq [[1], [2]]
  end

  def quarter_note_piano
    HeadMusic::Content::Flow.new(meter: "4/4").tap do |piano_flow|
      piano = piano_flow.add_part(instrument: "piano", staff_system: HeadMusic::Content::StaffSystem.grand_staff)
      hands = %w[right left].map { |hand| piano.add_voice(role: "#{hand} hand") }
      %w[1:1 1:2 1:3 1:4 2:1].each { |position| hands.each { |hand| hand.place(position, :quarter, "C4") } }
    end
  end

  it "numbers in document order, where each voice writes a whole bar in turn" do
    flow = quarter_note_piano
    right_hand, left_hand = flow.voices
    [[right_hand, "1:3", "2:1"], [left_hand, "1:1", "1:2"]].each { |hand, from, to| hand.add_span(:slur, from: from, to: to) }
    numbers = slur_numbers(flow)
    expect([numbers.starts_at(event_at(right_hand, "1:3")), numbers.starts_at(event_at(left_hand, "1:1"))]).to eq [[1], [2]]
  end

  it "refuses a seventeenth slur open at once" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nM:4/4\nK:C\n#{"C D E F|" * 5}\n")
    notes = flow.voices.first.voice_events
    notes.drop(1).first(17).each { |note| flow.voices.first.add_span(:slur, from: notes.first.position, to: note.position) }
    expect { HeadMusic::Notation::MusicXML::Writer.new(flow).to_s }.to raise_error(HeadMusic::Notation::MusicXML::RenderError, /more than 16 slurs/)
  end
end
