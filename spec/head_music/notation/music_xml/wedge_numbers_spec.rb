require "spec_helper"

describe HeadMusic::Notation::MusicXML::WedgeNumbers do
  def wedge_numbers(flow)
    described_class.new(flow.parts.first, HeadMusic::Notation::MusicXML::RenderPlan.new(flow))
  end

  def numbers_of(flow, owner)
    numbers = wedge_numbers(flow)
    owner.spans.select(&:hairpin?).map { |span| numbers.number(span) }
  end

  it "numbers a lone hairpin 1" do
    flow = HairpinFixtures.hairpin_under_held_note
    expect(numbers_of(flow, flow.voices.first)).to eq [1]
  end

  it "reuses a number where one hairpin ends and the next begins" do
    flow = HairpinFixtures.touching_hairpins_on_tied_note
    expect(numbers_of(flow, flow.voices.first)).to eq [1, 1]
  end

  it "gives a voice's hairpin open beside its part's its own number" do
    flow = HairpinFixtures.single_voice_part_hairpin
    flow.voices.first.add_span(:crescendo, from: "1:2", to: "1:4")
    expect([numbers_of(flow, flow.parts.first), numbers_of(flow, flow.voices.first)]).to eq [[1, 1], [2]]
  end

  it "numbers in document order, where the right hand's bar is written before the left hand's" do
    flow = HairpinFixtures.hairpins_in_two_voices
    right_hand, left_hand = flow.voices
    expect([numbers_of(flow, right_hand), numbers_of(flow, left_hand)]).to eq [[1, 2], [1]]
  end

  # A piano part of whole notes in each bar, each voice holding a crescendo.
  def crowded_piano(voices:, bars:, to:)
    HeadMusic::Content::Flow.new(name: "Crowded", meter: "4/4").tap do |flow|
      piano = flow.add_part(instrument: "piano")
      voices.times { |index| piano.add_voice(role: "voice #{index + 1}") }
      piano.voices.each { |voice| (1..bars).each { |bar| voice.place("#{bar}:1", :whole, "C4") } }
      piano.voices.each { |voice| voice.add_span(:crescendo, from: "1:1", to: to) }
    end
  end

  it "reuses a number in the next voice once the first voice's wedge stops in the same bar, as written" do
    flow = crowded_piano(voices: 2, bars: 1, to: "2:1")
    expect(flow.voices.flat_map { |voice| numbers_of(flow, voice) }).to eq [1, 1]
  end

  it "holds sixteen hairpins open at once" do
    flow = crowded_piano(voices: 16, bars: 2, to: "2:3")
    expect(flow.voices.flat_map { |voice| numbers_of(flow, voice) }).to eq (1..16).to_a
  end

  it "refuses a seventeenth hairpin open at once" do
    flow = crowded_piano(voices: 16, bars: 2, to: "2:3")
    flow.parts.first.add_span(:crescendo, from: "1:1", to: "2:3")
    expect { HeadMusic::Notation::MusicXML::Writer.new(flow).to_s }
      .to raise_error(HeadMusic::Notation::MusicXML::RenderError, /more than 16 wedges open at once in a part, at 1:1:000/)
  end
end
