require "spec_helper"

describe HeadMusic::Notation::MEI::MarkingEvents do
  def document(flow)
    parse_mei(HeadMusic::Notation::MEI.render(flow))
  end

  def controls(flow, name, *attributes)
    mei_attributes(document(flow), "//mei:measure/mei:#{name}", *attributes)
  end

  def abc(body)
    HeadMusic::Notation::ABC.parse("X:1\nT:Marks\nM:4/4\nL:1/4\nK:C\n#{body}\n")
  end

  describe "ornaments" do
    let(:flow) { MarkingFixtures.marked_melody }

    it "writes a trill and a turn at their notes" do
      expect([controls(flow, "trill", "startid"), controls(flow, "turn", "startid")])
        .to eq [["#m1-p1v1-b2c1"], ["#m1-p1v1-b5c4"]]
    end

    it "writes the mordent as the lower and the inverted mordent as the upper" do
      expect(controls(flow, "mordent", "startid", "form")).to eq [%w[#m1-p1v1-b5c1 lower], %w[#m1-p1v1-b5c3 upper]]
    end

    it "points a chord's ornament at the chord" do
      chord = abc("[CEG] D E F|]").tap { |chordal| chordal.voices.first.voice_events.first.embellish(:trill) }
      expect(mei_element_by_id(document(chord), controls(chord, "trill", "startid").first.delete("#")).name).to eq "chord"
    end
  end

  describe "dynamics" do
    it "writes a note dynamic at its note" do
      dynamics = mei_elements(document(MarkingFixtures.marked_melody), "//mei:dynam[@startid]")
      expect(dynamics.map { |dynam| [dynam.attributes["startid"], dynam.text] }).to eq [%w[#m1-p1v1-b2c3 sfz], %w[#m1-p1v1-b4c2 fp]]
    end

    it "writes a voice's level at its beat, on its staff and layer" do
      expect(controls(MarkingFixtures.marked_melody, "dynam[@tstamp]", "tstamp", "staff", "layer"))
        .to eq [%w[1 1 1], %w[3 1 1], %w[1 1 1], %w[3 1 1]]
    end

    it "writes a level inside a held note at its own beat" do
      flow = MarkingFixtures.grand_staff_piano_with_dynamics
      expect(controls(flow, "dynam", "xml:id", "tstamp")).to include(%w[m1-dynam-p1-b2c3 3])
    end

    it "writes a part's level on its top staff, with no layer" do
      flow = MarkingFixtures.grand_staff_piano_with_dynamics
      expect(controls(flow, "dynam", "xml:id", "staff", "layer")).to eq [
        ["m1-dynam-p1-b1c1", "1", nil], ["m1-dynam-p1-b2c3", "1", nil],
        %w[m1-dynam-p1v1-b3c1 1 1], ["m1-dynam-p1-b4c1", "1", nil]
      ]
    end

    it "writes a voice's level on the staff the voice is on in that bar" do
      flow = LilyPondFixtures.cross_staff_piano.tap { |piano| piano.voices.last.place_dynamic("2:1", :f) }
      expect(controls(flow, "dynam", "staff", "layer")).to eq [%w[1 2]]
    end
  end

  describe "hairpins" do
    it "writes a voice's hairpin with its form, its ends, and its staff and layer" do
      flow = HairpinFixtures.hairpin_under_held_note
      expect(controls(flow, "hairpin", "form", "tstamp", "tstamp2", "staff", "layer")).to eq [%w[cres 2 1m+2 1 1]]
    end

    it "writes a part's hairpin on its top staff, with no layer, one ending on the final barline" do
      flow = HairpinFixtures.part_hairpin
      expect(controls(flow, "hairpin", "xml:id", "form", "tstamp2", "layer")).to eq [
        ["m1-hairpin-p1-b1c1", "cres", "1m+3", nil], %w[m1-hairpin-p1v1-b2c3 cres 1m+1 1], ["m1-hairpin-p1-b3c1", "dim", "1m+5", nil]
      ]
    end

    it "writes a hairpin in the bar where it starts" do
      document = document(HairpinFixtures.hairpin_in_pickup)
      expect(mei_attributes(document, "//mei:measure[@n='0']/mei:hairpin", "tstamp", "tstamp2")).to eq [%w[2 1m+1]]
    end

    it "ends a hairpin past a short final bar's music at the final barline" do
      flow = HairpinFixtures.hairpins_after_short_final_bar
      expect(controls(flow, "hairpin", "form", "tstamp2")).to eq [%w[cres 0m+4], %w[dim 0m+5]]
    end
  end

  describe "slurs and phrases" do
    let(:flow) { MarkingFixtures.spanned_melody }

    it "writes each curve from its first note to its last" do
      expect([controls(flow, "slur", "startid", "endid").first, controls(flow, "phrase", "startid", "endid")])
        .to eq [%w[#m1-p1v1-b1c1 #m1-p1v1-b1c3], [%w[#m1-p1v1-b1c1 #m1-p1v1-b4c3]]]
    end

    it "ends a curve on the last piece of a note tied across a barline" do
      expect(controls(flow, "slur", "xml:id", "endid")).to include(%w[m1-slur-p1v1-b2c1-b2c4 #m1-p1v1-b3c1])
    end

    it "starts a curve on the first piece of a note crossing a barline" do
      expect(controls(flow, "slur", "xml:id", "startid")).to include(%w[m1-slur-p1v1-b3c4-b4c2 #m1-p1v1-b3c4])
    end

    it "ends a phrase on the first piece of a rest crossing a barline" do
      flow = MarkingFixtures.phrases_on_split_rest
      expect(controls(flow, "phrase", "startid", "endid")).to eq [
        %w[#m1-p1v1-b1c1 #m1-p1v1-b1c3], %w[#m1-p1v1-b1c3 #m1-p1v1-b2c3]
      ]
    end

    it "starts a slur from grace notes on the first grace note" do
      flow = TupletFixtures.grace_notes_before_downbeat
      expect(controls(flow, "slur", "xml:id", "startid", "endid")).to eq [%w[m1-slur-p1v1-b3c1g-b3c1 #m1-p1v1-b3c1-g1 #m1-p1v1-b3c1]]
    end

    it "keeps a slur from grace notes apart from one from their main note" do
      flow = abc("C D {B}E F|]").tap do |graced|
        graced.voices.first.add_span(:slur, from: "1:3", to: "1:4", from_grace: true)
        graced.voices.first.add_span(:slur, from: "1:3", to: "1:4")
      end
      expect(controls(flow, "slur", "xml:id").uniq.length).to eq 2
    end
  end

  it "orders a bar's controls by where they fall" do
    flow = MuseScoreFixtures.piano_part_marks
    expect(controls(flow, "*[not(self::mei:staff)]", "xml:id").first(3)).to eq %w[m1-dynam-p1-b1c1 m1-hairpin-p1-b1c1 m1-dynam-p1-b2c3]
  end
end
