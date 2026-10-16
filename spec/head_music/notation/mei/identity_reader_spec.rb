require "spec_helper"

describe HeadMusic::Notation::MEI::IdentityReader do
  def flow(head: mei_head, mdiv: "<mdiv>", music_label: nil, score_def: mei_score_def)
    HeadMusic::Notation::MEI.parse(mei_document(mei_staff(1, mei_note("C4", "1")), head: head, mdiv: mdiv, music_label: music_label, score_def: score_def))
  end

  def head(title_stmt: "<title>Head Title</title>", work_list: "")
    %(<meiHead><fileDesc><titleStmt>#{title_stmt}</titleStmt><pubStmt/></fileDesc>#{work_list}</meiHead>)
  end

  describe "#name" do
    it "is the mdiv's label" do
      expect(flow(mdiv: %(<mdiv label="Movement">), music_label: "Music").name).to eq "Movement"
    end

    it "is else the label of the music around it" do
      expect(flow(music_label: "Music").name).to eq "Music"
    end

    it "leaves out a title's typed parts, as sample-encodings writes a subordinate title" do
      title_stmt = %(<title>Herzliebster Jesu<titlePart type="subordinate">an electronic transcription</titlePart></title>)
      expect(flow(head: head(title_stmt: title_stmt)).name).to eq "Herzliebster Jesu"
    end

    it "is else the first untyped or main title, its editorial reading kept" do
      title_stmt = %(<title type="subordinate">Sub</title><title type="main">Main <choice><sic>Tilte</sic><corr>Title</corr></choice></title>)
      expect(flow(head: head(title_stmt: title_stmt)).name).to eq "Main Title"
    end
  end

  describe "#work" do
    def work_list(inside)
      "<workList><work><title>Opus</title>#{inside}</work></workList>"
    end

    it "comes from the work list, crediting a <composer>'s <persName> whatever its role" do
      work = flow(head: head(work_list: work_list(%(<composer><persName role="creator">Jane Doe</persName></composer>)))).work
      expect([work.title, work.composer]).to eq ["Opus", "Jane Doe"]
    end

    it "credits a <composer>'s own text and a persName of role composer" do
      inside = %(<composer>Ann</composer><respStmt><persName role="composer">Bea</persName><persName role="lyricist">Cy</persName></respStmt>)
      expect(flow(head: head(work_list: work_list(inside))).composer).to eq "Ann, Bea"
    end

    it "takes its catalog number from an <identifier> and its year from the date of its <creation>" do
      inside = %(<identifier type="opus">Op. 89</identifier><identifier type="work">D. 911</identifier><creation><date isodate="1827-02">1827</date></creation>)
      work = flow(head: head(work_list: work_list(inside))).work
      expect([work.catalog_number, work.year]).to eq ["D. 911", 1827]
    end

    it "reads a year from the text of a date with no @isodate, and none from loose text" do
      years = ["1950", "about 1950"].map { |text| flow(head: head(work_list: work_list("<creation><date>#{text}</date></creation>"))).work.year }
      expect(years).to eq [1950, nil]
    end

    it "takes a composer's life from the dates of their name, and their sort name from its parts" do
      name = %(<persName startdate="1901" enddate="1977-05-06"><foreName>Jane</foreName> <famName>Doe</famName></persName>)
      person = flow(head: head(work_list: work_list("<composer>#{name}</composer>"))).work.credits.first.person
      expect(person.to_h).to eq("full_name" => "Jane Doe", "sort_name" => "Doe, Jane", "birth_year" => 1901, "death_year" => 1977)
    end

    it "leaves out a life that ends before it begins, keeping the others" do
      names = %w[1901-1977 1977-1901].map { |life| %(<persName role="composer" startdate="#{life[0, 4]}" enddate="#{life[5, 4]}">#{life}</persName>) }
      work = flow(head: head(work_list: work_list("<respStmt>#{names.join}</respStmt>"))).work
      expect(work.credits.map { |credit| [credit.person.birth_year, credit.person.death_year] }).to eq [[1901, 1977], [nil, nil]]
    end

    it "is nil without a work list, whose composers become the flow's" do
      parsed = flow(head: head(title_stmt: %(<title>T</title><respStmt><persName role="composer">Dee</persName></respStmt>)))
      expect([parsed.work, parsed.composer]).to eq [nil, "Dee"]
    end
  end

  describe "#player and #instrument" do
    def part(staff_def)
      flow(score_def: mei_score_def(staff_grp: "<staffGrp>#{staff_def}</staffGrp>")).parts.first
    end

    it "names the player by the staff's label, as a Player with no project" do
      player = part(mei_staff_def(1, inside: "<label>Flute</label>")).player
      expect([player.name, player.project]).to eq ["Flute", nil]
    end

    it "names the instrument by the instrDef's label" do
      expect(part(mei_staff_def(1, inside: %(<instrDef label="clarinet_in_a" midi.instrnum="71"/>))).instrument.name_key).to eq :clarinet_in_a
    end

    it "falls back to the General MIDI program, numbered from 0" do
      expect(part(mei_staff_def(1, inside: %(<instrDef label="Whistle" midi.instrnum="40"/>))).instrument.name_key).to eq :violin
    end

    it "names no instrument where neither says one" do
      expect(part(mei_staff_def(1, inside: %(<instrDef midi.instrnum="52"/>))).instrument).to be_nil
    end
  end

  it "names a catalog instrument for every General MIDI program it lists" do
    expect(described_class::GM_PROGRAMS.values.reject { |name_key| HeadMusic::Instruments::Instrument.get(name_key) }).to be_empty
  end
end
