require "spec_helper"

describe HeadMusic::Notation::MEI do
  def piano(*measures)
    group = %(<staffGrp><staffGrp symbol="brace"><label>Piano</label>#{mei_staff_def(1)}#{mei_staff_def(2, clef: %w[F 4])}</staffGrp></staffGrp>)
    described_class.parse(mei_document(*measures, score_def: mei_score_def(staff_grp: group)))
  end

  def staves(flow)
    part = flow.parts.first
    part.voices.map { |voice| voice.staff_assignments.transform_values { |staff| part.staff_system.staves.index(staff) + 1 } }
  end

  describe "the writer's crossing voice" do
    let(:flow) { described_class.parse(File.read(MEIFixtures.path("cross_staff_piano"))) }

    it "crosses at the barlines where its layer moves to the other staff" do
      expect(staves(flow)).to eq [{}, {1 => 2, 2 => 1, 4 => 2}]
    end

    it "reads back the flow that was rendered" do
      expect(flow.to_mei).to eq File.read(MEIFixtures.path("cross_staff_piano"))
    end
  end

  describe "MuseScore's crossing layer" do
    def measure(staff)
      lower = staff ? mei_note("C3", "1", staff: staff) : mei_note("C3", "1")
      mei_staff(1, [1, mei_note("E5", "1")], [2, lower]) + mei_staff(2, [1, "<mRest/>"])
    end

    let(:flow) { piano(measure("2"), measure(nil), measure(nil), measure("2")) }

    it "sits a layer on the staff that every one of its notes names" do
      expect(staves(flow)).to eq [{}, {1 => 2, 2 => 1, 4 => 2}]
    end

    it "keeps the music whole" do
      expect_mei_music_whole(flow)
    end
  end

  it "opens a voice tacet in its first bars on the staff of its whole-bar rests" do
    rests = mei_staff(1, [1, mei_note("E5", "1")]) + mei_staff(2, [2, "<mRest/>"])
    notes = mei_staff(1, [1, mei_note("D5", "1")]) + mei_staff(2, [2, mei_note("C3", "1")])
    expect(staves(piano(rests, notes))).to eq [{}, {1 => 2}]
  end

  it "keeps a voice of only whole-bar rests on the staff of its rests" do
    rests = mei_staff(1, [1, mei_note("E5", "1")]) + mei_staff(2, [2, "<mRest/>"])
    expect(staves(piano(rests, rests))).to eq [{}, {1 => 2}]
  end

  it "reads a single part that opens with a staff definition rather than a scoreDef, as McFerrin's Don't Worry writes one" do
    staff_def = %(<staffDef n="1" lines="5" clef.shape="F" clef.line="4" meter.count="3" meter.unit="4" keysig="1s"/>)
    measure = %(<measure n="1">#{mei_staff(1, mei_note("G2", "2", dots: "1"))}</measure>)
    flow = described_class.parse(%(<mei xmlns="http://www.music-encoding.org/ns/mei">#{mei_head}<music><body><mdiv><parts><part>#{staff_def}<section>#{measure}</section></part></parts></mdiv></body></music></mei>))
    expect([flow.meter.to_s, flow.key_signature.name, flow.parts.first.staff_system.staves.first.clef.name_key.to_s, voice_event_strings(flow)])
      .to eq ["3/4", "G major", "bass_clef", [["dotted half G2 at 1:1:000"]]]
  end

  it "skips a single note's @staff" do
    flow = piano(mei_staff(1, mei_note("E4", "2", staff: "2") + mei_note("F4", "2")) + mei_staff(2, mei_note("C3", "1")), mei_staff(1, mei_note("E5", "1")) + mei_staff(2, mei_note("C3", "1")))
    expect(staves(flow)).to eq [{}, {1 => 2}]
  end

  it "skips a @staff naming a staff outside the part" do
    flow = piano(mei_staff(1, mei_note("E4", "1", staff: "9")) + mei_staff(2, mei_note("C3", "1")))
    expect(staves(flow).first).to eq({})
  end
end
