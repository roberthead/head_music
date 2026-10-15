require "spec_helper"

describe HeadMusic::Notation::MEI::EventWriter do
  def written(flow, bar_number = 1)
    plan = HeadMusic::Notation::MEI::RenderPlan.new(flow)
    writer = described_class.new(plan)
    plan.items(flow.voices.first, bar_number).flat_map { |item| [*writer.grace_elements(item), writer.element(item)] }
  end

  def lines(elements)
    elements.flat_map { |element| HeadMusic::Notation::MEI::Markup.lines(element) }
  end

  let(:flow) { HeadMusic::Content::Flow.new(meter: "4/4") }
  let(:voice) { flow.add_voice }

  it "writes a note's pitch and duration" do
    voice.place("1:1", :dotted_half, "F#4")
    voice.place("1:4", :quarter)
    note = %(<note xml:id="m1-p1v1-b1c1" pname="f" oct="4" dur="2" dots="1"/>)
    expect(lines(written(flow))).to eq [note, %(<rest xml:id="m1-p1v1-b1c4" dur="4"/>)]
  end

  it "writes a rest that fills its bar as a measure rest" do
    voice.place("1:1", :whole)
    expect(lines(written(flow))).to eq [%(<mRest xml:id="m1-p1v1-b1c1"/>)]
  end

  it "writes a chord's duration on the chord and its notes low to high" do
    voice.place("1:1", :whole, %w[G4 C4])
    expect(lines(written(flow))).to eq [
      %(<chord xml:id="m1-p1v1-b1c1" dur="1">), %(  <note xml:id="m1-p1v1-b1c1-h1" pname="c" oct="4"/>),
      %(  <note xml:id="m1-p1v1-b1c1-h2" pname="g" oct="4"/>), "</chord>"
    ]
  end

  it "ties each note of a chord split at the barline" do
    voice.place("1:3", :whole, %w[C4 E4])
    voice.place("1:1", :half)
    elements = written(flow, 1).last.children + written(flow, 2).first.children
    expect(elements.map { |note| note.attributes["tie"] }).to eq %w[i i t t]
  end

  describe "grace notes" do
    it "writes a slashed grace note as acciaccatura and another as appoggiatura" do
      note_event = voice.place("1:1", :whole, "C5")
      note_event.add_grace_note("D5", :eighth, slashed: true)
      note_event.add_grace_note("E5", :sixteenth)
      expect(written(flow).first(2).map { |grace| [grace.attributes["dur"], grace.attributes["grace"]] })
        .to eq [%w[8 acc], %w[16 unacc]]
    end

    it "writes a grace chord with the grace on the chord" do
      voice.place("1:1", :whole, "C5").add_grace_note(%w[E5 D5], :eighth)
      grace = written(flow).first
      expect([grace.name, grace.attributes["grace"], grace.children.map(&:id)])
        .to eq ["chord", "unacc", %w[m1-p1v1-b1c1-g1-h1 m1-p1v1-b1c1-g1-h2]]
    end

    it "ties grace notes into one another and into the note" do
      note_event = voice.place("1:1", :whole, "C5")
      note_event.add_grace_note("C5", :eighth, tied: true)
      note_event.add_grace_note("C5", :eighth, tied: true)
      expect(written(flow).map { |element| element.attributes["tie"] }).to eq %w[i m t]
    end

    it "carries a tie from a grace note through a note split at the barline" do
      voice.place("1:1", :half)
      voice.place("1:3", :whole, "C5").add_grace_note("C5", :eighth, tied: true)
      expect(written(flow).last(2).map { |element| element.attributes["tie"] }).to eq %w[i m]
    end

    it "ties only the pitches the grace note shares with what follows" do
      voice.place("1:1", :whole, %w[C5 E5]).add_grace_note("C5", :eighth, tied: true)
      expect(written(flow).last.children.map { |note| note.attributes["tie"] }).to eq ["t", nil]
    end
  end

  it "fills a bar a voice places nothing in with a measure rest" do
    voice.place("1:1", :whole, "C4")
    plan = HeadMusic::Notation::MEI::RenderPlan.new(flow)
    expect(described_class.new(plan).empty_bar_element(voice, 2)).to eq HeadMusic::Notation::MEI::Element.new("mRest", "m1-p1v1-b2c1")
  end
end
