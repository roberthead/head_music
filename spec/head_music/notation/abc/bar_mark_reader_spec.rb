require "spec_helper"

describe HeadMusic::Notation::ABC::BarMarkReader do
  subject(:reader) { described_class.new(flow) }

  let(:flow) { HeadMusic::Content::Flow.new }
  let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("C major") }
  let(:duration_resolver) { HeadMusic::Notation::ABC::DurationResolver.new("1/4") }
  let(:pitch_builder) { HeadMusic::Notation::ABC::PitchBuilder.new(key_signature) }
  let(:state) { HeadMusic::Notation::ABC::VoiceState.new(flow.add_voice(role: nil), pitch_builder, duration_resolver) }

  def token(type, **fields)
    HeadMusic::Notation::ABC::Token.new(type: type, line: 1, column: 1, **fields)
  end

  def bar(style = "|")
    state.place("4", nil)
    reader.bar_line(state, token(:bar_line, style: style))
  end

  it "marks a double barline on the bar it closes" do
    bar("||")
    expect(flow.bar(1).barline).to eq :double
  end

  it "marks a repeat from the bar a start repeat opens to the bar an end repeat closes" do
    bar("|:")
    bar(":|")
    expect([flow.bar(2).starts_repeat?, flow.bar(2).ends_repeat_after_num_plays]).to eq [true, 2]
  end

  it "refuses a volta with no passes" do
    expect { reader.volta(state, token(:volta, passes: [])) }
      .to raise_error(HeadMusic::Notation::ABC::ParseError, /no passes/)
  end

  it "labels the first bar for a part label before any voice" do
    reader.part_label(nil, token(:part_label, lexeme: "A"))
    reader.finish([])
    expect(flow.bar(1).rehearsal_mark).to eq "A"
  end

  it "ignores an empty part label" do
    reader.part_label(nil, token(:part_label, lexeme: ""))
    reader.finish([])
    expect(flow.bar(1).rehearsal_mark).to be_nil
  end

  it "treats a final barline on the last bar as implied" do
    bar("|]")
    reader.finish([state])
    expect(flow.bar(1).barline).to eq :regular
  end
end
