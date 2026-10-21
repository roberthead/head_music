require "spec_helper"

# The timeline expressions written to MEI and read back: tempo text, tempo
# changes, ramps, "a tempo" points, fermatas, and meter symbols. MEI holds
# all of them but a fermata's stretch, which reads back as the default the
# fixtures use, so the round trips leave nothing out.
describe HeadMusic::Notation::MEI do
  def round_trip(flow)
    described_class.parse(described_class.render(flow))
  end

  {"melody" => -> { TimelineExpressionFixtures.melody }, "chorale" => -> { TimelineExpressionFixtures.chorale }}.each do |name, build|
    describe "the #{name} fixture" do
      let(:flow) { build.call }

      it "keeps the meter symbol, tempo text, tempo changes, ramps, \"a tempo\" points, and fermatas" do
        expect_same_timeline(flow, round_trip(flow))
      end

      it "writes the same document from the flow it reads back" do
        rendered = described_class.render(flow)
        expect(described_class.render(described_class.parse(rendered))).to eq rendered
      end
    end
  end

  it "keeps an opening tempo's beat other than a quarter" do
    flow = HeadMusic::Content::Flow.new(meter: "6/8", tempo: "dotted quarter = 60").tap { |built| built.add_voice.place("1:1", :dotted_half, "C4") }
    expect(round_trip(flow).tempo).to eq flow.tempo
  end

  it "keeps a ramp's target at the final barline" do
    flow = HeadMusic::Content::Flow.new.tap { |built| built.add_voice.place("1:1", :whole, "C4") }
    flow.add_tempo_ramp(from: "1:3", to: "2:1", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 80), text: "rit.")
    expect_same_timeline(flow, round_trip(flow))
  end

  it "keeps a tempo of words alone, with no metronome mark" do
    flow = HeadMusic::Content::Flow.new(tempo: HeadMusic::Rudiment::Tempo.for_text("Andante con moto")).tap { |built| built.add_voice.place("1:1", :whole, "C4") }
    flow.voices.first.place("2:1", :whole, "D4")
    flow.change_tempo(2, HeadMusic::Rudiment::Tempo.new("quarter", 66, text: "Più lento", metronome_mark: false))
    expect_same_timeline(flow, round_trip(flow))
  end

  it "keeps a change of the meter's symbol alone" do
    flow = HeadMusic::Content::Flow.new(meter: "2/2").tap { |built| built.add_voice.place("1:1", :whole, "C4").voice.place("2:1", :whole, "D4") }
    flow.change_meter(2, HeadMusic::Rudiment::Meter.cut_time)
    expect_same_timeline(flow, round_trip(flow))
  end
end
