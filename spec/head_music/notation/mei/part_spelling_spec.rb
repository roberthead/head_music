require "spec_helper"

describe HeadMusic::Notation::MEI::PartSpelling do
  def spelled(*items, **options)
    found = []
    allow(described_class).to receive(:new).and_wrap_original do |original, *arguments|
      original.call(*arguments).tap do |spelling|
        allow(spelling).to receive(:pitches).and_wrap_original { |pitches, *inputs| pitches.call(*inputs).tap { |by_note| found << by_note } }
      end
    end
    HeadMusic::Notation::MEI.parse(mei_document(*items, **options))
    found.map { |by_note| by_note.values.map(&:to_s) }
  end

  def piano
    group = %(<staffGrp><staffGrp symbol="brace">#{mei_staff_def(1)}#{mei_staff_def(2, clef: %w[F 4])}</staffGrp></staffGrp>)
    mei_score_def(staff_grp: group)
  end

  it "holds an accidental for the later notes on its staff across the layers, in onset order" do
    upper = mei_note("F#4", "2") + mei_note("F4", "2", accid: "n")
    lower = mei_rest("4") + mei_note("F4", "4", accid: nil) + mei_rest("4") + mei_note("F4", "4", accid: nil)
    expect(spelled(mei_staff(1, [1, upper], [2, lower]))).to eq [%w[F♯4 F♯4 F4 F4]]
  end

  it "takes a grace note before the note it shares an onset with" do
    grace = %(<note pname="d" oct="4" dur="8" accid="s" grace="unacc"/>)
    expect(spelled(mei_staff(1, [1, mei_note("D4", "1", accid: nil)], [2, grace + mei_note("D4", "1", accid: nil)])))
      .to eq [%w[D♯4 D♯4 D♯4]]
  end

  it "spells a note on the staff its @staff names, with that staff's accidentals" do
    upper = mei_staff(1, [1, mei_note("C#4", "2") + mei_note("C4", "2", accid: nil, staff: "2")])
    lower = mei_staff(2, [1, mei_note("C4", "2", accid: nil) + mei_rest("2")])
    expect(spelled(upper + lower, score_def: piano)).to eq [%w[C♯4 C4 C4]]
  end

  it "sounds each note at its concert pitch" do
    staff_def = mei_staff_def(1, attributes: %( trans.diat="-1" trans.semi="-2"))
    expect(spelled(mei_staff(1, mei_note("D4", "1", accid: nil)), score_def: mei_score_def(staff_grp: "<staffGrp>#{staff_def}</staffGrp>")))
      .to eq [%w[C4]]
  end
end
