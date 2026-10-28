require "spec_helper"

describe HeadMusic::Notation::MEI::LyricWriter do
  let(:mei) { HeadMusic::Notation::MEI }
  let(:flow) { HeadMusic::Content::Flow.new(meter: "4/4") }
  let(:voice) { flow.add_voice }

  def written(bar_number = 1)
    allow(mei::EventWriter).to receive_messages(attribute_sources: [], child_sources: [described_class])
    plan = mei::RenderPlan.new(flow)
    writer = mei::EventWriter.new(plan)
    plan.items(voice, bar_number).flat_map { |item| [*writer.grace_elements(item), writer.element(item)] }
  end

  def lines(elements)
    elements.flat_map { |element| mei::Markup.lines(element) }
  end

  def syls(elements)
    elements.flat_map { |element| (element.name == "syl") ? [element] : syls(element.children) }
  end

  # Each entry is [duration, pitch, {verse => [text, hyphen_after]}].
  def sing(entries)
    entries.each do |rhythmic_value, pitch, verses|
      event = voice.place(voice.next_position, rhythmic_value, pitch)
      verses.each { |verse, (text, hyphen_after)| event.sing(text, verse: verse, hyphen_after: hyphen_after) }
    end
  end

  it "writes each syllable as a verse holding a syl" do
    voice.place("1:1", :whole, "C4").sing("love")
    expect(lines(written)[1..2]).to eq [
      %(  <verse xml:id="m1-p1v1-b1c1-verse1" n="1">), %(    <syl xml:id="m1-p1v1-b1c1-verse1-syl">love</syl>)
    ]
  end

  it "places a word's syllables from the hyphens, skipping notes that sing nothing" do
    sing([[:quarter, "C4", {1 => ["A", true]}], [:quarter, "D4", {1 => ["le", true]}], [:eighth, "E4", {1 => ["lu", true]}],
      [:eighth, "F4", {}], [:quarter, "G4", {1 => ["ia", false]}]])
    expect(syls(written).map { |syl| syl.attributes.slice("wordpos", "con").compact.values })
      .to eq [%w[i d], %w[m d], %w[m d], ["t"]]
  end

  it "follows each verse's words on their own" do
    sing([[:half, "C4", {1 => ["Ma", true], 2 => ["Lo", false]}], [:half, "D4", {1 => ["ry", false], 2 => ["ving", false]}]])
    expect(syls(written).map { |syl| [syl.id, syl.attributes["wordpos"]] }).to eq [
      ["m1-p1v1-b1c1-verse1-syl", "i"], ["m1-p1v1-b1c1-verse2-syl", nil],
      ["m1-p1v1-b1c3-verse1-syl", "t"], ["m1-p1v1-b1c3-verse2-syl", nil]
    ]
  end

  it "sings a chord on its lowest note only" do
    voice.place("1:1", :whole, %w[E4 C4]).sing("Ah")
    expect(written.first.children.map { |note| note.children.map(&:name) }).to eq [["verse"], []]
  end

  it "sings a note split at the barline on its first piece only" do
    voice.place("1:1", :half)
    voice.place("1:3", :whole, "C4").sing("hold")
    voice.place("2:3", :half)
    expect([syls(written(1)).map(&:text), syls(written(2))]).to eq [["hold"], []]
  end

  it "sings nothing on a grace note" do
    voice.place("1:1", :whole, "C4").tap { |event| event.add_grace_note("D4", :eighth) }.sing("la")
    expect(written.map { |element| element.children.map(&:name) }).to eq [[], ["verse"]]
  end

  it "escapes the syllable's text" do
    voice.place("1:1", :whole, "C4").sing("<&>")
    expect(lines(written)).to include(%(    <syl xml:id="m1-p1v1-b1c1-verse1-syl">&lt;&amp;&gt;</syl>))
  end

  describe "extenders" do
    def connectors
      syls(written).map { |syl| syl.attributes["con"] }
    end

    it "writes @con u on a word-final syllable whose melisma continues, and nothing on its held notes" do
      voice.place("1:1", :quarter, "C4").sing("Lord")
      voice.place("1:2", :quarter, "D4").extend_syllable
      voice.place("1:3", :half, "E4").sing("praise")
      expect(connectors).to eq ["u", nil]
    end

    it "writes @con d on a hyphenated melisma, since @con holds one value" do
      voice.place("1:1", :quarter, "C4").sing("Glo", hyphen_after: true)
      voice.place("1:2", :quarter, "D4").extend_syllable
      voice.place("1:3", :half, "E4").sing("ri")
      expect(connectors).to eq ["d", nil]
    end
  end
end
