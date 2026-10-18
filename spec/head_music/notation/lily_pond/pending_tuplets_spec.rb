require "spec_helper"

describe HeadMusic::Notation::LilyPond::PendingTuplets do
  subject(:brackets) { described_class.new }

  let(:flow) { TupletFixtures.flow("Brackets") }
  let(:voice) { TupletFixtures.fill(flow.add_voice, TupletFixtures.run("3:2", :eighth, %w[C4 D4 E4 F4 G4 A4])) }

  def bracketed
    voice.tuplets.map { |tuplet| [tuplet.from, tuplet.to] }
  end

  it "brackets the time from a start to a stop" do
    brackets.start(voice, flow.position("1:1"), nil)
    brackets.stop(voice, flow.position("1:3"))
    brackets.bracket
    expect(bracketed).to eq [[flow.position("1:1"), flow.position("1:3")]]
  end

  it "cuts a tuplet with a span into a bracket each span" do
    brackets.start(voice, flow.position("1:1"), Rational(1, 4))
    brackets.stop(voice, flow.position("1:3"))
    brackets.bracket
    expect(bracketed).to eq [[flow.position("1:1"), flow.position("1:2")], [flow.position("1:2"), flow.position("1:3")]]
  end

  it "ignores a stop with no start, and a tuplet that holds no time" do
    brackets.stop(voice, flow.position("1:2"))
    brackets.start(voice, flow.position("1:2"), nil)
    brackets.stop(voice, flow.position("1:2"))
    brackets.bracket
    expect(bracketed).to be_empty
  end

  it "leaves unbracketed the values of a bracket the voice refuses" do
    half_an_eighth = HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE / 24
    brackets.start(voice, flow.position("1:1").advance(subticks: half_an_eighth), nil)
    brackets.stop(voice, flow.position("1:3"))
    expect { brackets.bracket }.not_to raise_error
    expect(bracketed).to be_empty
  end
end
