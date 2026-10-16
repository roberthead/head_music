require "spec_helper"

describe HeadMusic::Notation::MEI::AccidentalPlan do
  let(:mei) { HeadMusic::Notation::MEI }

  def accidentals(flow, transposed: false)
    allow(mei::EventWriter).to receive_messages(attribute_sources: [described_class], child_sources: [])
    plan = mei::RenderPlan.new(flow, transposed: transposed)
    writer = mei::EventWriter.new(plan)
    elements = flow.voices.flat_map do |voice|
      plan.bar_numbers.flat_map do |bar_number|
        plan.items(voice, bar_number).flat_map { |item| [*writer.grace_elements(item), writer.element(item)] }
      end
    end
    notes(elements).map { |note| summary(note) }
  end

  def notes(elements)
    elements.flat_map { |element| (element.name == "note") ? [element] : notes(element.children) }
  end

  def summary(note)
    attributes = note.attributes
    marks = attributes.slice("accid", "accid.ges").map { |name, value| "#{name}=#{value}" }
    ["#{attributes["pname"]}#{attributes["oct"]}", *marks].join(" ")
  end

  def abc(body, key: "C", meter: "4/4")
    HeadMusic::Notation::ABC.parse("X:1\nT:Accidentals\nM:#{meter}\nL:1/4\nK:#{key}\n#{body}|]\n")
  end

  it "writes what the key implies as gestural and the rest as written" do
    expect(accidentals(abc("F^F=FB", key: "G"))).to eq ["f4 accid.ges=s", "f4 accid.ges=s", "f4 accid=n", "b4"]
  end

  it "carries an accidental through the bar and drops it at the barline" do
    expect(accidentals(abc("^FF=FF|F4"))).to eq ["f4 accid=s", "f4 accid.ges=s", "f4 accid=n", "f4", "f4"]
  end

  it "shows the accidental again in another octave of the same letter" do
    expect(accidentals(abc("^F^fF2"))).to eq ["f4 accid=s", "f5 accid=s", "f4 accid.ges=s"]
  end

  it "writes double sharps and double flats" do
    expect(accidentals(abc("^^F__BF^F"))).to eq ["f4 accid=x", "b4 accid=ff", "f4 accid.ges=ss", "f4 accid=s"]
  end

  it "reads a signature past seven sharps as double sharps" do
    flow = HeadMusic::Content::Flow.new(meter: "4/4", key_signature: "G# major")
    voice = flow.add_voice
    voice.place("1:1", :half, "F##4")
    voice.place("1:3", :half, "C#4")
    expect(accidentals(flow)).to eq ["f4 accid.ges=ss", "c4 accid.ges=s"]
  end

  describe "a tied continuation" do
    it "shows nothing across the barline and leaves the next bar's memory alone" do
      expect(accidentals(abc("z2z^F-|F^FF2"))).to eq ["f4 accid=s", "f4 accid.ges=s", "f4 accid=s", "f4 accid.ges=s"]
    end

    it "keeps a natural against the key as gestural" do
      expect(accidentals(abc("z3=F-|FF2z", key: "G"))).to eq ["f4 accid=n", "f4 accid.ges=n", "f4 accid.ges=s"]
    end
  end

  describe "a chord" do
    def chord_then(chord, after, key: nil)
      flow = HeadMusic::Content::Flow.new(meter: "4/4", key_signature: key)
      voice = flow.add_voice
      voice.place("1:1", :half, chord)
      voice.place("1:3", :half, after)
      accidentals(flow)
    end

    it "shows a natural beside a sharp at the same letter and octave, remembering the sharp" do
      expect(chord_then(%w[F4 F#4], "F#4")).to eq ["f4 accid=n", "f4 accid=s", "f4 accid.ges=s"]
    end

    it "shows a flat the key implies beside a natural, remembering the natural" do
      expect(chord_then(%w[Bb4 B4], "B4", key: "F major")).to eq ["b4 accid=f", "b4 accid=n", "b4"]
    end

    it "judges members without such a clash one by one, low to high" do
      expect(chord_then(%w[F4 A4 F#5], "F5")).to eq ["f4", "a4", "f5 accid=s", "f5 accid=n"]
    end

    it "shows the clash on a grace chord" do
      flow = HeadMusic::Content::Flow.new(meter: "4/4")
      flow.add_voice.place("1:1", :whole, "G4").add_grace_note(%w[F4 F#4], :eighth)
      expect(accidentals(flow)).to eq ["f4 accid=n", "f4 accid=s", "g4"]
    end
  end

  # Each layer is a list of [position, duration, pitch].
  def one_staff(*layers)
    HeadMusic::Content::Flow.new(meter: "4/4").tap do |flow|
      part = flow.add_part
      layers.each do |events|
        voice = part.add_voice
        events.each { |position, rhythmic_value, pitch| voice.place(position, rhythmic_value, pitch) }
      end
    end
  end

  it "shares the memory of a staff across its layers in onset order" do
    flow = one_staff([["1:1", :half, "F#5"], ["1:3", :half, "F#4"]], [["1:1", :quarter, "F#4"], ["1:2", :dotted_half, "F4"]])
    expect(accidentals(flow)).to eq ["f5 accid=s", "f4 accid=s", "f4 accid=s", "f4 accid=n"]
  end

  it "keeps a separate memory for each staff" do
    flow = HeadMusic::Content::Flow.new(meter: "4/4")
    flow.add_voice.place("1:1", :whole, "F#4")
    flow.add_voice.place("1:1", :whole, "F#4")
    expect(accidentals(flow)).to eq ["f4 accid=s", "f4 accid=s"]
  end

  describe "grace notes" do
    it "judges them before their note" do
      expect(accidentals(abc("{^F}F3"))).to eq ["f4 accid=s", "f4 accid.ges=s"]
    end

    it "shows nothing on the note a grace note ties into" do
      flow = HeadMusic::Content::Flow.new(meter: "4/4", key_signature: "G major")
      flow.add_voice.place("1:1", :whole, "F4").add_grace_note("F4", :eighth, tied: true)
      expect(accidentals(flow)).to eq ["f4 accid=n", "f4"]
    end
  end

  it "uses the part's written key in a transposed render" do
    project = LayoutFixtures.clarinet_project(pitches: %w[E4 E4])
    written = project.add_layout(concert_pitch: false).realize(project.flows.first)
    expect(accidentals(written, transposed: true)).to eq ["f4 accid.ges=s", "f4 accid.ges=s"]
  end

  it "answers nothing for chords and rests" do
    plan = mei::RenderPlan.new(abc("[CE]z3"))
    node = mei::EventWriter::Node.new(kind: :chord, id: "m1-p1v1-b1c1", item: nil)
    expect(described_class.new(plan).event_attributes(node)).to eq({})
  end
end
