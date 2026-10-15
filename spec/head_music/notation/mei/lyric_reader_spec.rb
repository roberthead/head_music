require "spec_helper"

describe HeadMusic::Notation::MEI::LyricReader do
  def read(content)
    HeadMusic::Notation::MEI.parse(mei_document(mei_staff(1, content)))
  end

  def syllables(flow)
    flow.voices.first.voice_events.map { |event| event.syllables.transform_values(&:to_h) }
  end

  def note(inside, dur = "4", **attributes)
    open = mei_note("C4", dur, **attributes).delete_suffix("/>")
    "#{open}>#{inside}</note>"
  end

  it "reads each <verse>'s <syl> as verse n, a verse with no @n as verse 1" do
    flow = read(note(%(<verse n="2"><syl>two</syl></verse><verse><syl>one</syl></verse>), "1"))
    expect(syllables(flow)).to eq [{1 => {"text" => "one"}, 2 => {"text" => "two", "verse" => 2}}]
  end

  it "reads a bare <syl> and @syl as verse 1" do
    flow = read(note(%(<syl>Ky</syl>), "2") + mei_note("C4", "2", syl: "ri"))
    expect(syllables(flow)).to eq [{1 => {"text" => "Ky"}}, {1 => {"text" => "ri"}}]
  end

  it "ranks the verse @n values that are no number after the highest numbered verse, in order of first appearance" do
    verses = ->(*labels) { note(labels.map { |label| %(<verse n="#{label}"><syl>#{label}</syl></verse>) }.join, "2") }
    flow = read(verses.call("refrain", "2") + verses.call("1", "chorus", "refrain"))
    expect(syllables(flow).map { |sung| sung.transform_values { |syllable| syllable["text"] } }).to eq [{3 => "refrain", 2 => "2"}, {1 => "1", 4 => "chorus", 3 => "refrain"}]
  end

  it "ranks a part's verses from 1 where none has a number" do
    flow = read(note(%(<verse n="a"><syl>one</syl></verse><verse n="b"><syl>two</syl></verse>), "1"))
    expect(syllables(flow).first.keys).to eq [1, 2]
  end

  it "sets hyphen_after from @wordpos i or m, or @con d, and nothing from the other @con values" do
    syls = [%(wordpos="i"), %(wordpos="m"), %(con="d"), %(wordpos="t" con="u")]
    flow = read(syls.map { |attributes| note(%(<verse n="1"><syl #{attributes}>la</syl></verse>)) }.join)
    expect(syllables(flow).map { |sung| sung[1]["hyphen_after"] }).to eq [true, true, true, nil]
  end

  it "joins several <syl>s with an elision, and an <lb/> as a space" do
    flow = read(note(%(<verse><syl con="b">di</syl><syl>a</syl></verse>), "2") + note(%(<verse><syl>Glo<lb/>ry</syl><lb/><syl wordpos="i">be</syl></verse>), "2"))
    expect(syllables(flow)).to eq [{1 => {"text" => "di‿a"}}, {1 => {"text" => "Glo ry be", "hyphen_after" => true}}]
  end

  it "reads a chord tone's syllable onto its chord, the first winning" do
    chord = %(<chord dur="1">#{note(%(<verse><syl>low</syl></verse>), nil)}#{note(%(<verse><syl>high</syl></verse>), nil)}</chord>)
    expect(syllables(read(chord))).to eq [{1 => {"text" => "low"}}]
  end

  describe "the lyrics it skips" do
    let(:content) do
      note(%(<verse><syl>grace</syl></verse>), "8", grace: "unacc") +
        note(%(<verse n="2"><syl> </syl></verse><verse n="3"><syl>sung</syl></verse>), "2", tie: "i") +
        note(%(<verse><syl>tied</syl></verse>), "4", tie: "t") + %(<rest dur="4"><verse><syl>rest</syl></verse></rest>)
    end

    it "skips lyrics on rests, grace notes, and a tie's later link, and empty ones" do
      expect(syllables(read(content))).to eq [{3 => {"text" => "sung", "verse" => 3}}, {}]
    end

    it "keeps the grace note it skips the lyric of" do
      expect(read(content).voices.first.note_events.first.grace_notes.length).to eq 1
    end
  end

  it "reads back the golden's two verses" do
    name = "two_verses"
    sung = ->(flow) { flow.voices.map { |voice| voice.voice_events.map { |event| event.syllables.transform_values(&:to_h) } } }
    flow = HeadMusic::Notation::MEI.parse(File.read(MEIFixtures.path(name)))
    expect(sung.call(flow)).to eq sung.call(MEIFixtures.source(name))
    expect(sung.call(flow).flatten.sum(&:size)).to eq 28
  end
end
