require "spec_helper"

# The core reads in linear time: doubling the bars at most doubles the
# positions it builds, the meters it looks up, and the voice events it
# searches back from, and every voice is placed in order, so none is ever
# revised. It counts calls rather than timing them.
describe HeadMusic::Notation::MusicXML::FlowBuilder do
  def counted
    {
      position: [HeadMusic::Content::Position, :initialize],
      meter_at: [HeadMusic::Content::Flow, :meter_at],
      voice_event_preceding: [HeadMusic::Content::Voice, :voice_event_preceding]
    }
  end

  # Each bar of each part: a grace note and a triplet group in the upper
  # voice, and in the lower a half note tied across the barline.
  def upper_bar
    triplet = "<time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification>"
    "<note><grace slash=\"yes\"/>#{pitch_xml("D5")}<voice>1</voice><type>16th</type></note>" +
      note_xml("C5", 1, "eighth", voice: 1, after: triplet, notations: %(<tuplet type="start"/>)) +
      note_xml("D5", 1, "eighth", voice: 1, after: triplet) +
      note_xml("E5", 1, "eighth", voice: 1, after: triplet, notations: %(<tuplet type="stop"/>)) +
      note_xml("F5", 3, "quarter", voice: 1) + note_xml("G5", 6, "half", voice: 1)
  end

  def lower_bar(first, last)
    note_xml("E4", 3, "quarter", voice: 2, inside: first ? "" : %(<tie type="stop"/>)) +
      note_xml("D4", 3, "quarter", voice: 2) +
      note_xml("E4", 6, "half", voice: 2, inside: last ? "" : %(<tie type="start"/>))
  end

  def document(bars)
    part = (1..bars).map { |bar| upper_bar + backup_xml(12) + lower_bar(bar == 1, bar == bars) }
    musicxml_document(part, part, attributes: opening_attributes(divisions: 3))
  end

  # The calls each counted method takes to read a document of so many bars,
  # and the flow it reads.
  def measure(bars)
    xml = document(bars)
    counts = Hash.new(0)
    traces = counted.map do |name, (owner, method)|
      TracePoint.new(:call) { counts[name] += 1 }.tap { |trace| trace.enable(target: owner.instance_method(method)) }
    end
    [counts, HeadMusic::Notation::MusicXML.parse(xml)]
  ensure
    traces&.each(&:disable)
  end

  it "reads in linear time, leaving every voice unrevised" do
    (small, _), (large, flow) = measure(250), measure(500)
    expect(counted.keys.to_h { |name| [name, large[name].fdiv(small[name]).round(2)] }.values).to all(be <= 2.2)
    expect(flow.voices.map { |voice| voice.voice_events.length }).to eq [2500, 1001, 2500, 1001]
    expect(flow.voices.map(&:revision)).to all(be_zero)
  end
end
