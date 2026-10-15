require "spec_helper"

describe HeadMusic::Notation::MEI::ContainerSpans do
  def controls(flow)
    described_class.new(HeadMusic::Notation::MEI::RenderPlan.new(flow)).controls
  end

  def summary(bar_elements)
    bar_elements.map { |bar_element| [bar_element.bar_number, bar_element.element.name, bar_element.element.id, bar_element.element.attributes] }
  end

  it "is a control source of the measure writer" do
    expect(HeadMusic::Notation::MEI::MeasureWriter.control_sources).to include described_class
  end

  it "places nothing where every container nests" do
    expect(controls(TupletFixtures.triplets)).to eq []
  end

  it "writes a tupletSpan in the bar where a bracket across a barline starts" do
    expect(summary(controls(TupletFixtures.tuplet_crossing_barline))).to eq [[
      1, "tupletSpan", "m1-tupletspan-p1v1-b1c4",
      {"num" => 3, "numbase" => 2, "staff" => 1, "layer" => 1, "startid" => "#m1-p1v1-b1c4", "endid" => "#m1-p1v1-b2c1t320"}
    ]]
  end

  describe "beams that cut across a tuplet" do
    let(:spans) { summary(controls(MEILayerFixtures.beams_across_tuplet)) }

    it "writes a beamSpan for each in its bar" do
      expect(spans.map { |bar_number, name, id, _| [bar_number, name, id] }).to eq [
        [1, "beamSpan", "m1-beamspan-p1v1-b1c1"], [1, "beamSpan", "m1-beamspan-p1v1-b1c2"]
      ]
    end

    it "names its ends and lists its members" do
      expect(spans.first.last).to eq(
        "staff" => 1, "layer" => 1, "startid" => "#m1-p1v1-b1c1", "endid" => "#m1-p1v1-b1c1t800",
        "plist" => "#m1-p1v1-b1c1 #m1-p1v1-b1c1t480 #m1-p1v1-b1c1t640 #m1-p1v1-b1c1t800"
      )
    end
  end

  it "names the staff a crossing voice is written on and its layer in the part" do
    spans = controls(MEILayerFixtures.left_hand_tuplet_across_barline)
    expect(spans.map { |bar_element| bar_element.element.attributes.values_at("staff", "layer") }).to eq [[2, 2]]
  end
end
