require "spec_helper"

describe HeadMusic::Notation::MEI::PartLayers do
  def filed(*items, **options)
    pending = nil
    reader = nil
    allow(described_class).to receive(:new).and_wrap_original do |original, *arguments|
      pending = arguments.last
      original.call(*arguments)
    end
    allow(HeadMusic::Notation::MEI::ScoreReader).to receive(:new).and_wrap_original do |original, *arguments|
      reader = original.call(*arguments)
    end
    HeadMusic::Notation::MEI.parse(mei_document(*items, **options))
    [reader.readings, pending]
  end

  let(:chord) { %(<chord dur="2">#{mei_note("C4", nil) + mei_note("E4", nil)}</chord>) }

  it "adds each entry's Pending records to the score's, a chord's tones after it" do
    _, pending = filed(mei_staff(1, chord + mei_rest("2")))
    expect(pending.map { |record| [record.kind, record.chord_member] }).to eq [[:chord, false], [:note, true], [:note, true], [:rest, false]]
  end

  it "records a <multiRest> as a whole-bar rest" do
    _, pending = filed(mei_staff(1, %(<multiRest num="2"/>)), mei_staff(1, mei_note("C4", "1")))
    expect(pending.map(&:kind)).to eq %i[m_rest note]
  end

  it "files each layer's entries with the sounds of their notes and their Pending records" do
    readings, _ = filed(mei_staff(1, chord + mei_note("G4", "2")))
    entries = readings.first.layers.first.entries
    expect(entries.map { |_, sounds, records| [sounds.map(&:to_s), records.length] }).to eq [[%w[C4 E4], 3], [%w[G4], 1]]
  end

  it "sits a layer on the other staff of its part where every note names it" do
    group = %(<staffGrp><staffGrp symbol="brace">#{mei_staff_def(1)}#{mei_staff_def(2, clef: %w[F 4])}</staffGrp></staffGrp>)
    staves = mei_staff(1, [1, mei_note("E5", "1")], [2, mei_note("C3", "1", staff: "2")]) + mei_staff(2, [1, "<mRest/>"])
    readings, _ = filed(staves, score_def: mei_score_def(staff_grp: group))
    expect(readings.first.layers.map { |layer| [layer.content.staff_number, layer.staff] }).to eq [[1, 1], [1, 2], [2, 2]]
  end
end
