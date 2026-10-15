require "spec_helper"

describe HeadMusic::Notation::MEI do
  def parse(*items, **options)
    described_class.parse(mei_document(*items, **options))
  end

  def piano(*measures)
    group = %(<staffGrp><staffGrp symbol="brace"><label>Piano</label>#{mei_staff_def(1)}#{mei_staff_def(2, clef: %w[F 4])}</staffGrp></staffGrp>)
    parse(*measures, score_def: mei_score_def(staff_grp: group))
  end

  describe "voice keys" do
    it "keys voices by layer number alone where no layer number holds notes on two staves in a bar, as the writer numbers them" do
      flow = piano(mei_staff(1, [1, mei_note("E5", "1")]) + mei_staff(2, [2, mei_note("C3", "1")]), mei_staff(1, [1, mei_note("E5", "1")], [2, mei_note("C4", "1")]))
      expect(voice_event_strings(flow)).to eq [["whole E5 at 1:1:000", "whole E5 at 2:1:000"], ["whole C3 at 1:1:000", "whole C4 at 2:1:000"]]
    end

    it "keys voices by staff and layer where one layer number holds notes on two staves in a bar" do
      flow = piano(mei_staff(1, mei_note("E5", "1")) + mei_staff(2, mei_note("C3", "1")), mei_staff(1, mei_note("F5", "1")) + mei_staff(2, mei_note("D3", "1")))
      expect(voice_event_strings(flow)).to eq [["whole E5 at 1:1:000", "whole F5 at 2:1:000"], ["whole C3 at 1:1:000", "whole D3 at 2:1:000"]]
    end

    it "reads no voice of a staff and layer that holds no notes anywhere" do
      measure = mei_staff(1, [1, mei_note("E5", "1")], [2, %(<space dur="1"/>)]) + mei_staff(2, mei_note("C3", "1"))
      expect(piano(measure, measure).voices.length).to eq 2
    end

    it "reads the layer of a voice that has notes where another layer of its number has a whole-bar rest" do
      flow = piano(mei_staff(1, [1, mei_note("E5", "1")], [2, mei_note("C3", "1", staff: "2")]) + mei_staff(2, [1, "<mRest/>"]))
      expect(voice_event_strings(flow)).to eq [["whole E5 at 1:1:000"], ["whole C3 at 1:1:000"]]
    end

    it "reads a layer with no @n as layer 1" do
      expect(voice_event_strings(parse(%(<staff n="1"><layer>#{mei_note("C4", "1")}</layer></staff>)))).to eq [["whole C4 at 1:1:000"]]
    end

    it "takes each voice's role from its layerDef's label" do
      staff_def = mei_staff_def(1, inside: %(<layerDef n="1"><label>upper</label></layerDef><layerDef n="2" label="lower"/>))
      flow = parse(mei_staff(1, [1, mei_note("E5", "1")], [2, mei_note("C4", "1")]), score_def: mei_score_def(staff_grp: "<staffGrp>#{staff_def}</staffGrp>"))
      expect(flow.voices.map { |voice| voice.role.to_s }).to eq %w[upper lower]
    end
  end

  describe "whole-bar rests and missing layers" do
    let(:note) { mei_staff(1, mei_note("C4", "1")) }
    let(:rest) { mei_staff(1, "<mRest/>") }

    it "places nothing for a voice's leading and trailing bars of only <mRest> or <mSpace>" do
      flow = parse(rest, mei_staff(1, "<mSpace/>"), note, rest)
      expect(voice_event_strings(flow)).to eq [["whole C4 at 3:1:000"]]
    end

    it "fills such bars between a voice's events, and missing layers, with rests" do
      flow = parse(mei_staff(1, [1, mei_note("C5", "1")], [2, mei_note("C4", "1")]), mei_staff(1, [1, mei_note("D5", "1")], [2, "<mRest/>"]), mei_staff(1, [1, mei_note("E5", "1")]), mei_staff(1, [1, mei_note("F5", "1")], [2, mei_note("F4", "1")]))
      expect(voice_event_strings(flow).last).to eq ["whole C4 at 1:1:000", "whole rest at 2:1:000", "whole rest at 3:1:000", "whole F4 at 4:1:000"]
    end

    it "places nothing for a bare staff" do
      flow = parse(note, %(<staff n="1"/>), note)
      expect(voice_event_strings(flow)).to eq [["whole C4 at 1:1:000", "whole rest at 2:1:000", "whole C4 at 3:1:000"]]
    end

    it "pads a short layer to its barline" do
      flow = parse(note, mei_staff(1, [1, mei_note("C5", "1")], [2, mei_note("C4", "2")]))
      expect(voice_event_strings(flow).last).to eq ["half C4 at 2:1:000", "half rest at 2:3:000"]
    end

    it "keeps the music whole" do
      flow = parse(mei_staff(1, [1, mei_note("C5", "1")], [2, "<mRest/>"]), mei_staff(1, [1, "<mRest/>"], [2, mei_note("E4", "4")]), rest, note)
      expect_mei_music_whole(flow)
    end
  end
end
