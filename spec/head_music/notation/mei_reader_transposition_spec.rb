require "spec_helper"

describe HeadMusic::Notation::MEI do
  def events(*items, **options)
    described_class.parse(mei_document(*items, **options)).voices.first.voice_events.map(&:to_s)
  end

  def clarinet(attributes)
    mei_score_def(staff_grp: "<staffGrp>#{mei_staff_def(1, attributes: attributes)}</staffGrp>")
  end

  def staff_def_change(attributes)
    %(<scoreDef><staffGrp><staffDef n="1"#{attributes}/></staffGrp></scoreDef>)
  end

  def whole(pitch)
    mei_staff(1, mei_note(pitch, "1"))
  end

  describe "the transposed clarinet golden" do
    let(:flow) { described_class.parse(File.read(MEIFixtures.path("clarinet_changes_transposed"))) }

    it "reads in concert pitch" do
      expect(flow.voices.first.voice_events.map(&:to_s)).to eq MEIFixtures.source("clarinet_changes_transposed").voices.first.voice_events.map(&:to_s)
    end

    it "renders back byte for byte through a transposed layout" do
      project = HeadMusic::Content::Project.new(name: "Study")
      project.add_flow(flow)
      expect(project.add_layout(concert_pitch: false).to_mei).to eq File.read(MEIFixtures.path("clarinet_changes_transposed"))
    end
  end

  it "sounds a staff's written pitches by its opening @trans.diat and @trans.semi" do
    expect(events(whole("D4"), score_def: clarinet(%( trans.diat="-1" trans.semi="-2")))).to eq ["whole C4 at 1:1:000"]
  end

  it "replaces it at a later staff definition, and returns to concert pitch at 0/0" do
    items = [whole("D4"), staff_def_change(%( trans.diat="-2" trans.semi="-3")), whole("Eb4"), staff_def_change(%( trans.diat="0" trans.semi="0")), whole("C4")]
    expect(events(*items, score_def: clarinet(%( trans.diat="-1" trans.semi="-2"))))
      .to eq ["whole C4 at 1:1:000", "whole C4 at 2:1:000", "whole C4 at 3:1:000"]
  end

  it "moves by octaves, which MEI counts in @trans.diat and @trans.semi" do
    expect(events(whole("C5"), score_def: clarinet(%( trans.diat="-7" trans.semi="-12")))).to eq ["whole C4 at 1:1:000"]
  end

  it "spells a @trans.semi alone by the diatonic steps its interval usually takes" do
    expect(events(whole("A4"), score_def: clarinet(%( trans.semi="-9")))).to eq ["whole C4 at 1:1:000"]
  end

  it "transposes only the staff that states it" do
    group = %(<staffGrp symbol="brace"><label>Organ</label>#{mei_staff_def(1)}#{mei_staff_def(2, clef: %w[F 4], attributes: %( trans.diat="-7" trans.semi="-12"))}</staffGrp>)
    flow = described_class.parse(mei_document(mei_staff(1, mei_note("C5", "1")) + mei_staff(2, [2, mei_note("C3", "1")]), score_def: mei_score_def(staff_grp: "<staffGrp>#{group}</staffGrp>")))
    expect(flow.voices.map { |voice| voice.voice_events.map(&:to_s) }).to eq [["whole C5 at 1:1:000"], ["whole C2 at 1:1:000"]]
  end
end
