require "spec_helper"

describe HeadMusic::Notation::MusicXML::MarkingElements do
  describe ".articulation_element" do
    it "maps every catalog articulation to a MusicXML element" do
      elements = HeadMusic::Rudiment::Articulation.all.map { |articulation| described_class.articulation_element(articulation) }
      expect(elements).to eq %w[staccato staccatissimo accent tenuto strong-accent]
    end
  end

  describe ".ornament_element" do
    it "maps every catalog ornament to a MusicXML element" do
      elements = HeadMusic::Rudiment::Ornament.all.map { |ornament| described_class.ornament_element(ornament) }
      expect(elements).to eq %w[trill-mark mordent inverted-mordent turn]
    end

    it "names the lower mordent <mordent> and the upper <inverted-mordent>" do
      lower = HeadMusic::Rudiment::Ornament.get(:mordent)
      upper = HeadMusic::Rudiment::Ornament.get(:inverted_mordent)
      expect([described_class.ornament_element(lower), described_class.ornament_element(upper)]).to eq %w[mordent inverted-mordent]
    end
  end

  describe ".dynamic_element" do
    it "maps every catalog accent to its own element name" do
      elements = HeadMusic::Rudiment::Dynamic.accents.map { |accent| described_class.dynamic_element(accent) }
      expect(elements).to eq %w[sf sfz rfz fp]
    end
  end

  describe "reading an element back" do
    it "inverts every articulation" do
      articulations = HeadMusic::Rudiment::Articulation.all
      expect(articulations.map { |articulation| described_class.articulation(described_class.articulation_element(articulation)) }).to eq articulations
    end

    it "reads <strong-accent> as marcato" do
      expect(described_class.articulation("strong-accent").name_key).to eq "marcato"
    end

    it "inverts every ornament" do
      ornaments = HeadMusic::Rudiment::Ornament.all
      expect(ornaments.map { |ornament| described_class.ornament(described_class.ornament_element(ornament)) }).to eq ornaments
    end

    it "inverts every accent" do
      accents = HeadMusic::Rudiment::Dynamic.accents
      expect(accents.map { |accent| described_class.dynamic(described_class.dynamic_element(accent)) }).to eq accents
    end

    it "answers nil for an element it does not write" do
      expect([described_class.articulation("breath-mark"), described_class.ornament("wavy-line"), described_class.dynamic("ff")]).to eq [nil, nil, nil]
    end
  end
end
