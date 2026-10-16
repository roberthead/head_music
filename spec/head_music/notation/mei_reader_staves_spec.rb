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

  it "skips a single note's @staff" do
    flow = piano(mei_staff(1, mei_note("E4", "2", staff: "2") + mei_note("F4", "2")) + mei_staff(2, mei_note("C3", "1")), mei_staff(1, mei_note("E5", "1")) + mei_staff(2, mei_note("C3", "1")))
    expect(staves(flow)).to eq [{}, {1 => 2}]
  end

  it "skips a @staff naming a staff outside the part" do
    flow = piano(mei_staff(1, mei_note("E4", "1", staff: "9")) + mei_staff(2, mei_note("C3", "1")))
    expect(staves(flow).first).to eq({})
  end
end
