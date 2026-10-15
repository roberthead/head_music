require "spec_helper"

describe HeadMusic::Notation::MEI::HeadWriter do
  def head(flows, **options)
    lines = HeadMusic::Notation::MEI::Markup.lines(described_class.new(flows, **options).element)
    parse_mei(%(<mei xmlns="http://www.music-encoding.org/ns/mei">#{lines.join}</mei>))
  end

  def credits(document)
    mei_elements(document, "//mei:respStmt/mei:persName").map { |name| [name.attributes["role"], name.text] }
  end

  let(:bach) { HeadMusic::Content::Person.new(full_name: "Johann Sebastian Bach") }
  let(:luther) { HeadMusic::Content::Person.new(full_name: "Martin Luther") }
  let(:flow) { HeadMusic::Content::Flow.new(name: "Chorale", composer: "J. S. Bach") }

  describe "the title" do
    it "is the flow's name" do
      expect(mei_element(head([flow]), "//mei:title").text).to eq "Chorale"
    end

    it "is the work's title where the flow cites one" do
      flow.work = HeadMusic::Content::Work.new(title: "Ein feste Burg")
      expect(mei_element(head([flow]), "//mei:title").text).to eq "Ein feste Burg"
    end

    it "is the title it is given above all" do
      flow.work = HeadMusic::Content::Work.new(title: "Ein feste Burg")
      expect(mei_element(head([flow], title: "Chorales"), "//mei:title").text).to eq "Chorales"
    end
  end

  describe "the credits" do
    it "fall back to the flow's composer" do
      expect(credits(head([flow]))).to eq [["composer", "J. S. Bach"]]
    end

    it "name each person of the work's credits in their role" do
      flow.work = HeadMusic::Content::Work.new(title: "Ein feste Burg")
        .with_credit(bach, :composer).with_credit(luther, :lyricist)
      expect(credits(head([flow]))).to eq [["composer", "Johann Sebastian Bach"], ["lyricist", "Martin Luther"]]
    end

    it "name each arranger" do
      expect(credits(head([flow], arranger: ["Ann", "Bo"]))).to eq [["composer", "J. S. Bach"], ["arranger", "Ann"], ["arranger", "Bo"]]
    end

    it "name a person once across flows" do
      expect(credits(head([flow, flow]))).to eq [["composer", "J. S. Bach"]]
    end

    it "are left out where nobody is credited" do
      anonymous = HeadMusic::Content::Flow.new(name: "Anonymous")
      expect(mei_element(head([anonymous]), "//mei:respStmt")).to be_nil
    end
  end

  it "names the application and its version" do
    application = mei_element(head([flow]), "//mei:appInfo/mei:application")
    expect([application.attributes["version"], application.elements["name"].text]).to eq [HeadMusic::VERSION, "head_music"]
  end
end
