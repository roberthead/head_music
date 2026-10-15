require "spec_helper"

describe HeadMusic::Notation::SpanEnds do
  let(:flow) { HeadMusic::Content::Flow.new(meter: "4/4") }
  let(:voice) { flow.add_voice }

  def closing(voice_event)
    [[true, false], [false, false], [false, true]].map do |first, last|
      described_class.closing_piece?(voice_event, first: first, last: last)
    end
  end

  it "closes a note on its last piece" do
    expect(closing(voice.place("1:1", :whole, "C4"))).to eq [false, false, true]
  end

  it "closes a rest on its first piece" do
    expect(closing(voice.place("1:1", :whole))).to eq [true, false, false]
  end
end
