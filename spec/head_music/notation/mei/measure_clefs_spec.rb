require "spec_helper"

describe HeadMusic::Notation::MEI::MeasureClefs do
  subject(:clefs) { described_class.new }

  let(:definition) { HeadMusic::Notation::MEI::StaffGroups::PartDefinition.new(index: 0, staff_numbers: [1, 2], staff_defs: {}, group: nil) }
  let(:reading) { HeadMusic::Notation::MEI::PartReading.new(definition) }
  let(:treble) { HeadMusic::Rudiment::Clef.get(:treble_clef) }
  let(:bass) { HeadMusic::Rudiment::Clef.get(:bass_clef) }
  let(:alto) { HeadMusic::Rudiment::Clef.get(:alto_clef) }
  let(:no_changes) { HeadMusic::Notation::MEI::StaffState::Changes.new(clefs: {}, instruments: {}, transpositions: {}) }

  def measure(index, extent: Rational(1))
    HeadMusic::Notation::MEI::PartReading::Measure.new(index: index, extent: extent, clefs: {})
  end

  def content(staff_number, extent: Rational(1), opening_clef: nil, closing_clef: nil)
    HeadMusic::Notation::MEI::LayerReader::Content.new(
      staff_number: staff_number, entries: [], extent: extent, opening_clef: opening_clef, closing_clef: closing_clef
    )
  end

  it "opens a measure with the clef that closed a full layer of the bar before" do
    clefs.close(reading, measure(0), [content(1, closing_clef: bass), content(2, extent: Rational(1, 2), closing_clef: alto)])
    following = measure(1)
    clefs.open(reading, following, no_changes, [content(1)])
    expect(following.clefs).to eq(1 => bass)
  end

  it "lets a layer's opening clef, then a change between measures, win over a closing one" do
    clefs.close(reading, measure(0), [content(1, closing_clef: bass), content(2, closing_clef: bass)])
    following = measure(1)
    changes = HeadMusic::Notation::MEI::StaffState::Changes.new(clefs: {2 => treble, 3 => alto}, instruments: {}, transpositions: {})
    clefs.open(reading, following, changes, [content(1, opening_clef: alto), content(1, opening_clef: treble)])
    expect(following.clefs).to eq(1 => alto, 2 => treble)
  end

  it "leaves the first measure's clefs to the staff definitions" do
    first = measure(0)
    clefs.open(reading, first, no_changes, [content(1, opening_clef: bass)])
    expect(first.clefs).to be_empty
  end
end
