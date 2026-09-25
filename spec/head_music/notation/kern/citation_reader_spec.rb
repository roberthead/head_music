require "spec_helper"

describe HeadMusic::Notation::Kern::CitationReader do
  def flow(*references)
    HeadMusic::Notation::Kern.parse([*references, "**kern", "1c", "*-"].join("\n"))
  end

  describe "a chorale's citation" do
    subject(:work) do
      flow(
        "!!!!SEGMENT: chorale.krn",
        "!!!COM: Bach, Johann Sebastian",
        "!!!CDT: 1685/02/21/-1750/07/28/",
        "!!!OTL@@DE: Aus meines Herzens Grunde",
        "!!!OTL@EN: From the Depths of My Heart",
        "!!!SCT: BWV 269",
        "!!!ODT: 1736/",
        "!!!AGN: chorale"
      ).work
    end

    let(:composer) { work.credits.for(:composer).first.person }

    it "takes the title from the original-language title" do
      expect(work.title).to eq "Aus meines Herzens Grunde"
    end

    it "takes the catalog number verbatim" do
      expect(work.catalog_number).to eq "BWV 269"
    end

    it "takes the first year of the date" do
      expect(work.year).to eq 1736
    end

    it "credits the composer with the full name first and the record as the sort name" do
      expect([composer.full_name, composer.sort_name]).to eq ["Johann Sebastian Bach", "Bach, Johann Sebastian"]
    end

    it "sets a sole composer's birth and death years" do
      expect([composer.birth_year, composer.death_year]).to eq [1685, 1750]
    end

    it "names the flow for the title, so the flow and the work agree" do
      expect(flow("!!!OTL: Air", "!!!COM: Anonymous").name).to eq "Air"
    end
  end

  it "prefers !!!OTL over !!!OTL@@xx" do
    expect(flow("!!!OTL@@DE: Grunde", "!!!OTL: Heart").work.title).to eq "Heart"
  end

  it "takes a name without a comma as both full and sort name" do
    person = flow("!!!OTL: Air", "!!!COM: Josquin").work.credits.first.person
    expect([person.full_name, person.sort_name]).to eq %w[Josquin Josquin]
  end

  it "credits several composers, in order, and ignores !!!CDT" do
    work = flow("!!!OTL: Air", "!!!COM: Lennon, John", "!!!COM: McCartney, Paul", "!!!CDT: 1940-1980").work
    expect(work.credits.map { |credit| [credit.person.full_name, credit.person.birth_year] })
      .to eq [["John Lennon", nil], ["Paul McCartney", nil]]
  end

  it "reads years marked as approximate" do
    person = flow("!!!OTL: Missa", "!!!COM: Desprez, Josquin", "!!!CDT: ~1450/-1521/08/27/").work.credits.first.person
    expect([person.birth_year, person.death_year]).to eq [1450, 1521]
  end

  ["1685", "someday", "1750/-1685/", "-1750"].each do |dates|
    it "ignores a composer date it cannot use (#{dates})" do
      person = flow("!!!OTL: Air", "!!!COM: Bach, Johann Sebastian", "!!!CDT: #{dates}").work.credits.first.person
      expect([person.birth_year, person.death_year]).to eq [nil, nil]
    end
  end

  it "builds no work without a title" do
    expect(flow("!!!COM: Bach, Johann Sebastian").work).to be_nil
  end

  it "makes the composers of an untitled file the flow's composer string" do
    expect(flow("!!!COM: Lennon, John", "!!!COM: McCartney, Paul").composer).to eq "John Lennon, Paul McCartney"
  end

  it "leaves a file with neither title nor composer without either" do
    parsed = flow
    expect([parsed.work, parsed.composer, parsed.name]).to eq [nil, nil, "Composition"]
  end

  it "leaves a work without a date or catalog number without them" do
    expect(flow("!!!OTL: Air").work.to_h.slice("catalog_number", "year")).to eq("catalog_number" => nil, "year" => nil)
  end
end
