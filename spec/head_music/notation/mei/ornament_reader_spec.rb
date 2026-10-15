require "spec_helper"

describe HeadMusic::Notation::MEI::OrnamentReader do
  def read(content, controls = "")
    HeadMusic::Notation::MEI.parse(mei_document(mei_staff(1, content) + controls))
  end

  def ornaments(flow)
    flow.voices.first.voice_events.map { |event| event.ornaments.map(&:name_key) }
  end

  let(:notes) { %w[a b c d].map { |id| mei_note("C4", "4", "xml:id": id) }.join }

  it "reads <trill>, <mordent>, and <turn> onto the note they start at" do
    controls = %(<trill startid="#a"/><mordent startid="#b" form="lower"/><mordent startid="#c" form="upper"/><turn startid="#d"/>)
    expect(ornaments(read(notes, controls))).to eq [%w[trill], %w[mordent], %w[inverted_mordent], %w[turn]]
  end

  it "reads a <mordent> with no @form as the mordent, and MEI 4's forms as theirs" do
    controls = %(<mordent startid="#a"/><mordent startid="#b" form="norm"/><mordent startid="#c" form="inv"/><turn startid="#d" form="upper"/>)
    expect(ornaments(read(notes, controls))).to eq [%w[mordent], %w[mordent], %w[inverted_mordent], %w[turn]]
  end

  it "reads an ornament at a beat that a note starts on" do
    expect(ornaments(read(notes, %(<trill staff="1" tstamp="2"/>)))).to eq [[], %w[trill], [], []]
  end

  it "reads an ornament at a chord tone onto its chord" do
    chord = %(<chord dur="1">#{mei_note("C4", nil, "xml:id": "low")}#{mei_note("E4", nil)}</chord>)
    expect(ornaments(read(chord, %(<trill startid="#low"/>)))).to eq [%w[trill]]
  end

  it "skips an inverted turn, an ornament at a rest or a grace note, and one at a beat no note starts on" do
    content = mei_note("D4", "8", grace: "unacc", "xml:id": "g") + mei_note("C4", "2", "xml:id": "a") + mei_rest("4", "xml:id": "r") + mei_note("E4", "4", "xml:id": "e")
    controls = %(<turn startid="#e"/><turn startid="#a" form="lower"/><trill startid="#r"/><mordent startid="#g"/><trill staff="1" tstamp="1.5"/>)
    flow = nil
    expect { flow = read(content, controls) }.not_to raise_error
    expect(ornaments(flow)).to eq [[], [], %w[turn]]
  end

  it "reads back the golden's ornaments" do
    name = "articulations_ornaments_dynamics"
    flow = HeadMusic::Notation::MEI.parse(File.read(MEIFixtures.path(name)))
    expect(ornaments(flow)).to eq ornaments(MEIFixtures.source(name))
    expect(ornaments(flow).flatten.sort).to eq %w[inverted_mordent mordent trill turn]
  end
end
