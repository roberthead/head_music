require "spec_helper"

describe HeadMusic::Notation::MEI::StaffState do
  let(:mei) { HeadMusic::Notation::MEI }

  def state_for(*staff_defs)
    score_def = %(<scoreDef keysig="0" meter.count="4" meter.unit="4"><staffGrp>#{staff_defs.join}</staffGrp></scoreDef>)
    source = mei::Parser.new(mei_document(mei_staff(1, mei_note("C4", "1")), score_def: score_def)).document.sources.first
    element = source.editorial.children_named(source.score, "scoreDef").first
    groups = mei::StaffGroups.new(element, source.editorial, score: source.score)
    described_class.new(mei::OpeningValues.new(element, groups, source.editorial), groups, source.editorial, mei::IdentityReader.new(source, groups))
  end

  describe "#steps" do
    it "lists the transposition of each staff written in one" do
      state = state_for(mei_staff_def(1, attributes: %( trans.diat="-1" trans.semi="-2")), mei_staff_def(2))
      expect(state.steps).to eq(1 => HeadMusic::Notation::ConcertTransposition::Step.new(-1, -2, 0))
    end

    it "is empty for a score in concert pitch" do
      expect(state_for(mei_staff_def(1)).steps).to eq({})
    end
  end
end
