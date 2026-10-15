require "spec_helper"

describe HeadMusic::Notation::MEI::ArticReader do
  def read(*measures)
    HeadMusic::Notation::MEI.parse(mei_document(*measures))
  end

  def articulations(flow)
    flow.voices.first.voice_events.map { |event| event.articulations.map(&:name_key) }
  end

  it "reads @artic and <artic>, each list of values, onto their notes" do
    flow = read(mei_staff(1, mei_note("C4", artic: "stacc acc") + %(<note pname="d" oct="4" dur="4"><artic artic="ten"/><artic artic="marc stacciss"/></note>) + mei_rest("2")))
    expect(articulations(flow)).to eq [%w[accent staccato], %w[marcato staccatissimo tenuto], []]
  end

  it "reads a chord's articulations and its tones' onto the chord" do
    chord = %(<chord dur="1" artic="stacc">#{mei_note("C4", nil, artic: "ten")}<note pname="e" oct="4"><artic artic="acc"/></note></chord>)
    expect(articulations(read(mei_staff(1, chord)))).to eq [%w[accent staccato tenuto]]
  end

  it "reads a tied note's articulations from its first link only" do
    flow = read(mei_staff(1, mei_note("C4", "1", tie: "i", artic: "ten")), mei_staff(1, mei_note("C4", "1", tie: "t", artic: "stacc")))
    expect(articulations(flow)).to eq [%w[tenuto]]
  end

  it "skips values the model has no articulation for, and articulations on rests" do
    flow = read(mei_staff(1, mei_note("C4", "2", artic: "spicc stacc") + mei_rest("2", artic: "acc")))
    expect(articulations(flow)).to eq [%w[staccato], []]
  end

  it "reads an <artic> through the editorial rule" do
    note = %(<note pname="c" oct="4" dur="1"><app><lem><artic artic="ten"/></lem><rdg><artic artic="stacc"/></rdg></app></note>)
    expect(articulations(read(mei_staff(1, note)))).to eq [%w[tenuto]]
  end

  it "reads a grace note's articulations onto the grace note" do
    flow = read(mei_staff(1, mei_note("D4", "8", grace: "unacc", artic: "stacc") + %(<chord dur="8" grace="acc"><artic artic="ten"/>#{mei_note("E4", nil)}#{mei_note("G4", nil, artic: "acc")}</chord>) + mei_note("C4", "1")))
    graces = flow.voices.first.voice_events.first.grace_notes
    expect(graces.map { |grace| grace.articulations.map(&:name_key) }).to eq [%w[staccato], %w[accent tenuto]]
  end

  it "reads back the golden's articulations" do
    name = "articulations_ornaments_dynamics"
    flow = HeadMusic::Notation::MEI.parse(File.read(MEIFixtures.path(name)))
    expect(articulations(flow)).to eq articulations(MEIFixtures.source(name))
  end

  it "reads back the golden's grace-note articulations" do
    name = "grace_notes_before_downbeat"
    graces = ->(flow) { flow.voices.flat_map(&:note_events).flat_map(&:grace_notes).map { |grace| grace.articulations.map(&:name_key) } }
    flow = HeadMusic::Notation::MEI.parse(File.read(MEIFixtures.path(name)))
    expect(graces.call(flow)).to eq graces.call(MEIFixtures.source(name))
    expect(graces.call(flow).flatten).to eq %w[staccato]
  end
end
