require "spec_helper"

describe HeadMusic::Notation::MusicXML::Writer do
  def document_for(flow)
    parse_musicxml(described_class.new(flow).to_s)
  end

  def durations(document, measure)
    xpath_texts(document, "//part/measure[@number='#{measure}']/note[not(chord)]/duration").map(&:to_i)
  end

  describe "divisions and durations" do
    it "writes every fixture" do
      TupletFixtures.all.each do |name|
        expect { described_class.new(TupletFixtures.public_send(name)).to_s }.not_to raise_error, name.to_s
      end
    end

    it "writes septuplet sixteenths as one seventh of a quarter each" do
      document = document_for(TupletFixtures.septuplet)
      expect([xpath_text(document, "//divisions"), durations(document, 1)]).to eq ["7", [1] * 7 + [21]]
    end

    it "splits a triplet quarter across the barline into triplet eighths" do
      document = document_for(TupletFixtures.tuplet_crossing_barline)
      expect([durations(document, 1), durations(document, 2)]).to eq [[9, 2, 1], [1, 2, 9]]
    end

    it "splits a septuplet eighth at its exact barline though its position rounds" do
      document = document_for(TupletFixtures.septuplet_crossing_barline)
      expect([durations(document, 1), durations(document, 2)]).to eq [[21, 2, 2, 2, 1], [1, 2, 2, 2, 21]]
    end

    it "places a dynamic at a rounded septuplet onset at the note's exact onset" do
      flow = TupletFixtures.septuplet
      flow.parts.first.place_dynamic(flow.voices.first.voice_events[3].position, :p)
      document = document_for(flow)
      expect(xpath_text(document, "//measure[@number='1']/direction/offset")).to eq "3"
    end
  end
end
