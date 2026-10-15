require "spec_helper"

# The whole reader, mark readers and REXML included, reads in linear time:
# four times the bars, each with a slur, a hairpin, a level, lyrics, and
# beamed eighths, take under 4.5 times the method calls. It counts calls
# rather than timing them.
describe HeadMusic::Notation::MusicXML::Parser do
  def flow_of(bars)
    HeadMusic::Content::Flow.new(name: "Scaling", key_signature: "C major", meter: "4/4").tap do |flow|
      voice = flow.add_voice
      (1..bars).each { |bar| add_bar(flow, voice, bar) }
    end
  end

  def add_bar(flow, voice, bar)
    %w[C5 D5 E5 F5 G5 F5 E5 D5].each_with_index do |pitch, index|
      voice.place(flow.position(bar, (index / 2) + 1, (index % 2) * 480), :eighth, pitch).sing("la#{index}", verse: 1)
    end
    voice.place_dynamic("#{bar}:1", bar.odd? ? :p : :f)
    voice.add_span(:slur, from: "#{bar}:1", to: "#{bar}:2")
    voice.add_span(:crescendo, from: "#{bar}:3", to: "#{bar}:4")
  end

  # The HeadMusic and REXML methods called to read a document of so many
  # bars, and the flow read.
  def measure(bars)
    xml = HeadMusic::Notation::MusicXML.render(flow_of(bars))
    calls = 0
    trace = TracePoint.new(:call) do |point|
      calls += 1 if point.defined_class.to_s.match?(/\A(#<Class:)?(HeadMusic|REXML)::/)
    end
    flow = trace.enable { HeadMusic::Notation::MusicXML.parse(xml) }
    [calls, flow]
  end

  it "reads every mark of four times the bars in under 4.5 times the calls, leaving the voice unrevised" do
    (small, _), (large, flow) = measure(10), measure(40)
    expect(large.fdiv(small)).to be < 4.5
    owners = [flow.parts.first, flow.voices.first]
    expect([owners.sum { |owner| owner.spans.length }, owners.sum { |owner| owner.dynamic_events.length }, flow.voices.first.revision]).to eq [80, 40, 0]
  end
end
