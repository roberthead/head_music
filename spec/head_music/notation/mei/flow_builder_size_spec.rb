require "spec_helper"

# The reader runs in linear time: doubling the bars at most doubles the
# positions it builds, the meters it looks up, and the voice events it
# searches back from, it never walks the tree through XPath, and every voice
# is placed in order, so none is ever revised. It counts calls rather than
# timing them.
describe HeadMusic::Notation::MEI::FlowBuilder do
  def counted
    {
      position: [HeadMusic::Content::Position, :initialize],
      meter_at: [HeadMusic::Content::Flow, :meter_at],
      voice_event_preceding: [HeadMusic::Content::Voice, :voice_event_preceding]
    }
  end

  def xpath_calls
    [REXML::XPath.singleton_class.instance_method(:match), REXML::XPath.singleton_class.instance_method(:first), REXML::Elements.instance_method(:each)]
  end

  def note(id, pitch, dur, extra = "", inside: "")
    letter, octave = pitch.downcase.chars
    %(<note xml:id="#{id}" pname="#{letter}" oct="#{octave}" dur="#{dur}"#{extra}>#{inside}</note>)
  end

  # A grace note, triplet eighths under a verse, a quarter, and a half.
  # The first part's triplets are a <tuplet>; the second's, a <tupletSpan>.
  def upper_layer(part, bar)
    id = ->(name) { "p#{part}b#{bar}#{name}" }
    triplets = note(id.call("t1"), "C5", "8", inside: %(<verse n="1"><syl>la</syl></verse>)) + note(id.call("t2"), "D5", "8") + note(id.call("t3"), "E5", "8")
    triplets = %(<tuplet num="3" numbase="2">#{triplets}</tuplet>) if part == 1
    note(id.call("g"), "D5", "16", %( grace="acc")) + triplets + note(id.call("q"), "F5", "4") + note(id.call("h"), "G5", "2")
  end

  # A quarter tied in from the bar before, and a half tied out to the next,
  # by @tie in the first part and by <tie> in the second, around an <app>.
  def lower_layer(part, bar, bars)
    id = ->(name) { "p#{part}b#{bar}#{name}" }
    tie = ->(value, show) { (part == 1 && show) ? %( tie="#{value}") : "" }
    app = %(<app><lem>#{note(id.call("lem"), "D4", "4")}</lem><rdg>#{note(id.call("rdg"), "F4", "4")}</rdg></app>)
    note(id.call("in"), "E4", "4", tie.call("t", bar > 1)) + app + note(id.call("out"), "E4", "2", tie.call("i", bar < bars))
  end

  def controls(part, bar, bars)
    id = ->(name) { "#p#{part}b#{bar}#{name}" }
    [
      %(<slur staff="#{part}" startid="#{id.call("t1")}" endid="#{id.call("t3")}"/>),
      %(<dynam staff="#{part}" layer="1" tstamp="1">p</dynam>),
      %(<beamSpan staff="#{part}" layer="1" plist="#{id.call("t1")} #{id.call("t2")} #{id.call("t3")}"/>),
      %(<dir staff="#{part}" startid="#{id.call("rdg")}">rejected</dir>),
      (part == 2) ? %(<tupletSpan staff="2" num="3" numbase="2" startid="#{id.call("t1")}" endid="#{id.call("t3")}"/>) : "",
      (part == 2 && bar < bars) ? %(<tie staff="2" startid="#{id.call("out")}" endid="#p2b#{bar + 1}in"/>) : ""
    ].join
  end

  def document(bars)
    measures = (1..bars).map do |bar|
      staves = [1, 2].map { |part| mei_staff(part, [1, upper_layer(part, bar)], [2, lower_layer(part, bar, bars)]) }
      %(<measure n="#{bar}">#{staves.join}#{controls(1, bar, bars)}#{controls(2, bar, bars)}</measure>)
    end
    mei_document(*measures, score_def: mei_score_def(clefs: [%w[G 2], %w[G 2]]))
  end

  # The calls each counted method takes to read a document of so many bars,
  # the XPath walks among them, and a mark reader that kept every record.
  def measure(bars)
    xml = document(bars)
    counts = Hash.new(0)
    traces = counted.map do |name, (owner, method)|
      TracePoint.new(:call) { counts[name] += 1 }.tap { |trace| trace.enable(target: owner.instance_method(method)) }
    end
    traces += xpath_calls.map { |method| TracePoint.new(:call) { counts[:xpath] += 1 }.tap { |trace| trace.enable(target: method) } }
    [counts, MEIMarkRecorder.parse(xml)]
  ensure
    traces&.each(&:disable)
  end

  it "reads in linear time, without XPath, leaving every voice whole and unrevised" do
    (small, _), (large, recorder) = measure(250), measure(500)
    expect(counted.keys.to_h { |name| [name, large[name].fdiv(small[name]).round(2)] }.values).to all(be <= 2.2)
    expect([small[:xpath], large[:xpath]]).to eq [0, 0]
    expect(recorder.flow.voices.map { |voice| [voice.voice_events.length, voice.tuplets.length] }).to eq [[2500, 500], [1001, 0], [2500, 500], [1001, 0]]
    expect(recorder.flow.voices.map(&:revision)).to all(be_zero)
  end

  # Every Ruby method the whole reader calls, from the XML parse to the mark
  # readers, so that a quadratic step anywhere, not only in the methods
  # counted above, shows.
  def calls_to_read(bars)
    xml = document(bars)
    count = 0
    TracePoint.new(:call) { count += 1 }.enable { HeadMusic::Notation::MEI.parse(xml) }
    count
  end

  it "makes at most 4.5 times the calls to read four times the bars" do
    expect(calls_to_read(100).fdiv(calls_to_read(25))).to be < 4.5
  end

  # Each bar's nine events in each part, and its controls but the <dir>
  # naming a rejected reading: in each part a slur, a dynamic, and a
  # beamSpan by @plist, and in the second a tupletSpan and a <tie> to the
  # next bar.
  it "hands the mark readers every record, each span with both ends" do
    _, recorder = measure(500)
    controls = recorder.of(HeadMusic::Notation::MEI::ControlRecord)
    expect(recorder.records.map { |record| record.class.name.split("::").last }.tally)
      .to eq("MeasureRecord" => 500, "EventRecord" => 9000, "ControlRecord" => 3999)
    expect(controls.reject(&:span?).map { |record| [record.element.name, record.plist.length] }.tally).to eq(["dynam", 0] => 1000, ["beamSpan", 3] => 1000)
  end
end
