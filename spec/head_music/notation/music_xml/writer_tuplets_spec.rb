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

  describe "time modification and tuplets" do
    def notes(document, measure)
      REXML::XPath.match(document, "//part/measure[@number='#{measure}']/note")
    end

    def modification(note)
      element = note.elements["time-modification"]
      element && %w[actual-notes normal-notes normal-type].map { |name| element.elements[name]&.text }
    end

    def tuplets(note)
      REXML::XPath.match(note, "notations/tuplet").map { |tuplet| [tuplet.attributes["type"], tuplet.attributes["number"]] }
    end

    it "writes the ratio on every triplet note" do
      document = document_for(TupletFixtures.triplets)
      expect(notes(document, 1).map { |note| modification(note) }).to eq [["3", "2", nil]] * 9
    end

    it "starts and stops each bracket on its ends" do
      document = document_for(TupletFixtures.triplets)
      expect(notes(document, 1).map { |note| tuplets(note) }).to eq [[["start", "1"]], [], [["stop", "1"]]] * 3
    end

    it "keeps a sextuplet as one bracket of six" do
      document = document_for(TupletFixtures.sextuplet)
      expect(notes(document, 1).first(6).map { |note| [modification(note), tuplets(note)] }).to eq [
        [["6", "4", nil], [["start", "1"]]], *[[["6", "4", nil], []]] * 4, [["6", "4", nil], [["stop", "1"]]]
      ]
    end

    it "names the bracket unit where a note of another value is under it" do
      document = document_for(TupletFixtures.mixed_value_tuplet)
      expect(notes(document, 1).first(2).map { |note| modification(note) }).to eq [["3", "2", "eighth"], ["3", "2", nil]]
    end

    it "brackets a rest, and writes the ratio on every note of a chord but the bracket on its lead" do
      document = document_for(TupletFixtures.mixed_value_tuplet)
      rest, lead, member = notes(document, 1)[2, 3]
      expect([tuplets(rest), tuplets(lead), tuplets(member), modification(member)])
        .to eq [[["start", "1"]], [["stop", "1"]], [], ["3", "2", "eighth"]]
    end

    it "writes no ratio on the plain link of a chain ending a group" do
      document = document_for(TupletFixtures.triplet_tied_out)
      expect(notes(document, 1).first(4).map { |note| [modification(note), tuplets(note)] }).to eq [
        [["3", "2", nil], [["start", "1"]]], [["3", "2", nil], []], [["3", "2", nil], [["stop", "1"]]], [nil, []]
      ]
    end

    it "carries a bracket across the barline, with the ratio on both pieces of the split note" do
      document = document_for(TupletFixtures.tuplet_crossing_barline)
      written = (notes(document, 1).drop(1) + notes(document, 2).first(2)).map { |note| [modification(note), tuplets(note)] }
      expect(written).to eq [
        [["3", "2", nil], [["start", "1"]]], [["3", "2", "quarter"], []], [["3", "2", "quarter"], []], [["3", "2", nil], [["stop", "1"]]]
      ]
    end

    it "brackets an ungrouped run by threes" do
      document = document_for(TupletFixtures.ungrouped_tuplet_run)
      expect(notes(document, 1).first(6).map { |note| tuplets(note) }).to eq [[["start", "1"]], [], [["stop", "1"]]] * 2
    end

    it "numbers each voice's brackets by the voice" do
      document = document_for(TupletFixtures.tuplets_in_two_voices)
      numbers = REXML::XPath.match(document, "//note[notations/tuplet]").map do |note|
        [note.elements["voice"].text, note.elements["notations/tuplet"].attributes["number"]]
      end
      expect(numbers.uniq).to eq [%w[1 1], %w[2 2]]
    end

    it "writes the tuplet after the slur, inside notations" do
      flow = TupletFixtures.triplets
      flow.voices.first.add_span(:slur, from: "1:1", to: "1:2")
      note = notes(document_for(flow), 1).first
      expect(xpath_names(note, "notations/*")).to eq %w[slur tuplet]
    end

    it "writes the time modification after the dots and before the staff" do
      note = notes(document_for(TupletFixtures.tuplets_in_two_voices), 1).first
      expect(xpath_names(note, "*")).to eq %w[pitch duration voice type time-modification staff beam notations]
    end
  end
end
