require "spec_helper"

describe HeadMusic::Notation::MEI do
  def parse(*items, **options)
    described_class.parse(mei_document(*items, **options))
  end

  def bars(flow)
    flow.voices.first.voice_events.map { |event| event.position.bar_number }.uniq
  end

  describe "pickups" do
    it "reads a first measure of type upbeat as bar 0" do
      flow = parse(%(<measure n="0" type="upbeat">#{mei_staff(1, mei_rest("2", dots: "1") + mei_note("G4"))}</measure>), mei_staff(1, mei_note("C5", "1")))
      expect(flow.voices.first.voice_events.map(&:to_s)).to eq ["dotted half rest at 0:1:000", "quarter G4 at 0:4:000", "whole C5 at 1:1:000"]
    end

    it "reads a short first measure as a pickup, right-aligned, as n=0 with no type counts" do
      flow = parse(%(<measure n="0">#{mei_staff(1, mei_note("G4"))}</measure>), mei_staff(1, mei_note("C5", "1")))
      expect(flow.voices.first.voice_events.map(&:to_s)).to include("quarter G4 at 0:4:000", "whole C5 at 1:1:000")
    end
  end

  describe "short measures" do
    it "reads a final measure with metcon false as a short final bar" do
      flow = parse(mei_staff(1, mei_note("C4", "1")), %(<measure n="2" metcon="false">#{mei_staff(1, mei_note("D4", "2"))}</measure>))
      expect(flow.voices.first.voice_events.map(&:to_s)).to eq ["whole C4 at 1:1:000", "half D4 at 2:1:000"]
    end

    it "keeps a final measure with metcon false short beside another staff's whole-bar rest" do
      two_staves = {score_def: mei_score_def(clefs: [%w[G 2], %w[F 4]])}
      last = %(<measure n="2" metcon="false">#{mei_staff(1, mei_note("D4", "2"))}#{mei_staff(2, "<mRest/>")}</measure>)
      flow = parse(mei_staff(1, mei_note("C4", "1")) + mei_staff(2, mei_note("C3", "1")), last, **two_staves)
      expect(flow.voices.first.voice_events.map(&:to_s)).to eq ["whole C4 at 1:1:000", "half D4 at 2:1:000"]
    end

    it "joins a short measure to the one that completes it, as at a repeat in the middle of a bar" do
      halves = [%(<measure n="1" metcon="false">#{mei_staff(1, mei_note("C4", "2"))}</measure>), %(<measure n="1b" metcon="false">#{mei_staff(1, mei_note("D4", "2"))}</measure>)]
      expect(parse(mei_staff(1, mei_note("B3", "1")), *halves).voices.first.voice_events.map(&:to_s))
        .to eq ["whole B3 at 1:1:000", "half C4 at 2:1:000", "half D4 at 2:3:000"]
    end

    it "refuses a short measure in the middle that the next does not complete, naming it" do
      expect { parse(mei_staff(1, mei_note("B3", "1")), mei_staff(1, mei_note("C4", "2")), mei_staff(1, mei_note("D4", "1"))) }
        .to raise_error(described_class::UnsupportedFeatureError, /shorter than its 4\/4 bar.*measure 2/)
    end
  end

  describe "a <multiRest>" do
    it "fills as many bars as its @num" do
      flow = parse(mei_staff(1, mei_note("C4", "1")), mei_staff(1, %(<multiRest num="3"/>)), mei_staff(1, mei_note("D4", "1")))
      expect(flow.voices.first.voice_events.map(&:to_s).last).to eq "whole D4 at 5:1:000"
    end
  end

  describe "later definitions" do
    it "changes the meter from the next measure, and a restatement makes no change" do
      flow = parse(
        mei_staff(1, mei_note("C4", "1")), %(<scoreDef meter.count="3" meter.unit="4"/>), mei_staff(1, mei_note("D4", "2", dots: "1")),
        %(<scoreDef meter.count="3" meter.unit="4"/>), mei_staff(1, mei_note("E4", "2", dots: "1"))
      )
      expect(flow.meter_changes.transform_values(&:to_s)).to eq(2 => "3/4")
    end

    it "changes the meter where only the first staff's definition states it" do
      score_def = %(<scoreDef><staffGrp><staffDef n="1" meter.count="4" meter.unit="4"><clef shape="G" line="2"/></staffDef></staffGrp></scoreDef>)
      flow = parse(mei_staff(1, mei_note("C4", "1")), %(<staffDef n="1" meter.count="2" meter.unit="4"/>), mei_staff(1, mei_note("D4", "2")), score_def: score_def)
      expect(flow.meter_at(2).to_s).to eq "2/4"
    end

    it "changes the key with its mode" do
      flow = parse(mei_staff(1, mei_note("C4", "1")), %(<scoreDef keysig="3f" key.mode="minor"/>), mei_staff(1, mei_note("C4", "1")))
      expect(flow.key_signature_changes.transform_values { |event| event.key_signature.name }).to eq(2 => "C minor")
    end

    it "changes a staff's clef by a staff definition between measures" do
      flow = parse(mei_staff(1, mei_note("C4", "1")), %(<staffDef n="1"><clef shape="F" line="4"/></staffDef>), mei_staff(1, mei_note("C3", "1")))
      expect(flow.parts.first.staff_system.staves.first.clef_changes.transform_values { |clef| clef.name_key.to_s }).to eq(2 => "bass_clef")
    end

    it "changes a staff's clef by a clef that opens a layer, and skips one later in it" do
      flow = parse(
        mei_staff(1, mei_note("C4", "1")), mei_staff(1, %(<clef shape="F" line="4"/>) + mei_note("C3", "1")),
        mei_staff(1, mei_note("C3", "2") + %(<clef shape="G" line="2"/>) + mei_note("C4", "2"))
      )
      expect(flow.parts.first.staff_system.staves.first.clef_changes.transform_values { |clef| clef.name_key.to_s }).to eq(2 => "bass_clef")
    end

    it "changes a staff's clef at the next barline by a clef after a layer's last note, as MuseScore writes one" do
      flow = parse(mei_staff(1, mei_note("C4", "1") + %(<clef shape="F" line="4"/>)), mei_staff(1, mei_note("C3", "1")))
      expect(flow.parts.first.staff_system.staves.first.clef_changes.transform_values { |clef| clef.name_key.to_s }).to eq(2 => "bass_clef")
    end

    it "reads a clef change on the staff definitions of a later scoreDef" do
      later = %(<scoreDef><staffGrp><staffDef n="1" clef.shape="C" clef.line="3"/></staffGrp></scoreDef>)
      flow = parse(mei_staff(1, mei_note("C4", "1")), later, mei_staff(1, mei_note("C4", "1")))
      expect(flow.parts.first.staff_system.staves.first.clef_changes.transform_values { |clef| clef.name_key.to_s }).to eq(2 => "alto_clef")
    end

    it "changes the instrument where a staff definition brings a new instrDef" do
      later = %(<staffDef n="1"><instrDef label="flute"/></staffDef>)
      flow = parse(mei_staff(1, mei_note("C4", "1")), later, mei_staff(1, mei_note("C4", "1")),
        score_def: mei_score_def(staff_grp: %(<staffGrp>#{mei_staff_def(1, inside: %(<instrDef label="oboe"/>))}</staffGrp>)))
      expect(flow.parts.first.instrument_changes.transform_values(&:name_key)).to eq(2 => :flute)
    end

    it "skips a later staff definition for a staff the score never uses, as Brahms's Op. 51 No. 1 writes one" do
      flow = parse(mei_staff(1, mei_note("C4", "1")), %(<staffDef n="6"><clef shape="F" line="4"/></staffDef>), mei_staff(1, mei_note("D4", "1")))
      expect([flow.parts.length, flow.voices.first.voice_events.map(&:to_s)]).to eq [1, ["whole C4 at 1:1:000", "whole D4 at 2:1:000"]]
    end

    it "refuses a staff that a later staff definition adds" do
      later = [%(<staffDef n="2"><clef shape="F" line="4"/></staffDef>), mei_staff(1, mei_note("D4", "1")) + mei_staff(2, mei_note("C3", "1"))]
      expect { parse(mei_staff(1, mei_note("C4", "1")), *later) }
        .to raise_error(described_class::UnsupportedFeatureError, /<staff> numbered 2 is added by a later <staffDef>, which is not supported \(measure 2, <staff>\)/)
    end

    it "refuses a later scoreDef that adds or removes staves" do
      later = %(<scoreDef><staffGrp>#{mei_staff_def(1)}#{mei_staff_def(2)}</staffGrp></scoreDef>)
      expect { parse(mei_staff(1, mei_note("C4", "1")), later, mei_staff(1, mei_note("C4", "1"))) }
        .to raise_error(described_class::UnsupportedFeatureError, /adds or removes staves/)
    end
  end
end
