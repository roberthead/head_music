require "spec_helper"

describe HeadMusic::Notation::MEI::MeasureContents do
  def read(*items, **options)
    made = []
    readings = nil
    allow(described_class).to receive(:new).and_wrap_original { |original, *arguments, **keywords| original.call(*arguments, **keywords).tap { |contents| made << contents } }
    allow(HeadMusic::Notation::MEI::ScoreReader).to receive(:new).and_wrap_original do |original, *arguments|
      original.call(*arguments).tap { |reader| readings = reader.readings }
    end
    HeadMusic::Notation::MEI.parse(mei_document(*items, **options))
    [made, readings]
  end

  let(:two_staves) { mei_score_def(clefs: [%w[G 2], %w[F 4]]) }

  it "takes every child but the staves as a control event, in document order" do
    made, _ = read(%(<dir tstamp="1">a</dir>#{mei_staff(1, mei_note("C4", "1"))}<dynam tstamp="1">p</dynam>))
    expect(made.first.controls.map(&:name)).to eq %w[dir dynam]
  end

  it "reads each part's layers on its staves" do
    made, readings = read(mei_staff(2, mei_note("C3", "1")) + mei_staff(1, mei_note("C5", "1")), score_def: two_staves)
    expect(readings.map { |reading| made.first[reading].map(&:staff_number) }).to eq [[1], [2]]
  end

  it "counts the layers with notes that repeat a staff's layer number" do
    made, readings = read(mei_staff(1, [1, mei_note("C5", "1")], [1, mei_note("C4", "1")]))
    expect(made.first[readings.first].map(&:occurrence)).to eq [0, 1]
  end

  it "resolves a <space> with no length to what its layer leaves of the bar" do
    made, _ = read(mei_staff(1, [1, mei_note("C5", "1")], [2, mei_note("C4", "2") + "<space/>"]))
    expect(made.first.all.last.entries.last.duration).to eq Rational(1, 2)
  end

  it "lists every entry of the measure, and finds the <multiRest> that fills the most bars" do
    rests = mei_staff(1, %(<multiRest num="2"/>)) + mei_staff(2, %(<multiRest num="3"/>))
    made, _ = read(rests, mei_staff(1, mei_note("C5", "1")) + mei_staff(2, mei_note("C3", "1")), score_def: two_staves)
    expect([made.first.entries.length, made.first.longest_multi_rest.bars, made.last.longest_multi_rest]).to eq [2, 3, nil]
  end

  it "raises on a <staff> with no <staffDef>, and on one a later <staffDef> adds" do
    expect { read(mei_staff(2, mei_note("C4", "1"))) }.to raise_error(HeadMusic::Notation::MEI::ParseError, /numbered 2 has no <staffDef>/)
    expect { read(mei_staff(1, mei_note("C4", "1")), mei_staff_def(2), mei_staff(2, mei_note("C3", "1"))) }
      .to raise_error(HeadMusic::Notation::MEI::UnsupportedFeatureError, /added by a later <staffDef>/)
  end
end
