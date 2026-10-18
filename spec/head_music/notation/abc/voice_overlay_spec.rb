require "spec_helper"

describe HeadMusic::Notation::ABC::VoiceOverlay do
  subject(:overlay) { described_class.new(voice) }

  let(:flow) { HeadMusic::Content::Flow.new }
  let(:voice) { flow.add_voice(role: nil) }
  let(:note_token) { HeadMusic::Notation::ABC::Token.new(type: :note, line: 4, column: 1) }

  def position(code)
    HeadMusic::Content::Position.new(flow, code)
  end

  it "starts over the bar the last bar line opened" do
    overlay.bar_line(position("2:1:000"))
    overlay.start
    expect(overlay.cursor).to eq position("2:1:000")
  end

  it "starts over the first bar before any bar line" do
    overlay.start
    expect([overlay.active?, overlay.cursor]).to eq [true, position("1:1:000")]
  end

  it "moves its cursor by the time it holds" do
    overlay.start
    overlay.advance(HeadMusic::Rudiment::RhythmicValue.new(:half))
    expect(overlay.cursor).to eq position("1:3:000")
  end

  it "refuses music while active" do
    overlay.start
    expect { overlay.reject_music(note_token) }.to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /second voice/)
  end

  it "lets music through while inactive" do
    expect { overlay.reject_music(note_token) }.not_to raise_error
  end

  it "refuses to run past its bar's music" do
    overlay.start
    overlay.advance(HeadMusic::Rudiment::RhythmicValue.new(:half))
    expect { overlay.finish(position("1:2:000"), 5) }.to raise_error(HeadMusic::Notation::ABC::ParseError, /run past/)
  end

  it "ends within its bar's music" do
    overlay.start
    overlay.finish(position("1:2:000"), 5)
    expect(overlay).not_to be_active
  end
end
