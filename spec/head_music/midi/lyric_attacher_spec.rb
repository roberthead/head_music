require "spec_helper"

describe HeadMusic::MIDI::LyricAttacher do
  let(:flow) { HeadMusic::Content::Flow.new(name: "Lyrics") }
  let(:soprano_key) { HeadMusic::MIDI::PartKey.new(track: 1, channel: 0) }
  let(:alto_key) { HeadMusic::MIDI::PartKey.new(track: 2, channel: 1) }
  let(:soprano) { flow.add_part }
  let(:alto) { flow.add_part }
  let(:upper) { soprano.add_voice }
  let(:lower) { soprano.add_voice }
  let(:alto_voice) { alto.add_voice }

  let!(:upper_events) { {0r => upper.place("1:1", :half, "E5"), 1/2r => upper.place("1:3", :half, "F5")} }
  let!(:lower_events) { {0r => lower.place("1:1", :quarter, "C5"), 1/4r => lower.place("1:2", :quarter, "B4")} }
  let!(:alto_events) { {0r => alto_voice.place("1:1", :whole, "A4")} }
  let(:events_by_part) { {soprano_key => [upper_events, lower_events], alto_key => [alto_events]} }

  def lyric(track, time, text)
    [HeadMusic::MIDI::PartKey.new(track: track, channel: nil), time, text]
  end

  def sung(event)
    event.syllables.values.map { |syllable| [syllable.verse, syllable.text, syllable.hyphen_after?] }
  end

  def attach(*lyrics)
    described_class.new(lyrics, events_by_part).attach
  end

  it "sings on the first voice of its part with a note starting there" do
    attach(lyric(1, 0r, "Glo"))
    expect([sung(upper_events[0r]), sung(lower_events[0r])]).to eq [[[1, "Glo", false]], []]
  end

  it "reaches a later voice when the first has no note starting there" do
    attach(lyric(1, 1/4r, "ri"))
    expect(sung(lower_events[1/4r])).to eq [[1, "ri", false]]
  end

  it "strips whitespace and a trailing hyphen, which continues the word" do
    attach(lyric(1, 0r, " Glo- "), lyric(1, 1/2r, "ri\n"))
    expect([sung(upper_events[0r]), sung(upper_events[1/2r])]).to eq [[[1, "Glo", true]], [[1, "ri", false]]]
  end

  it "makes several lyrics at one onset successive verses, in order" do
    attach(lyric(1, 0r, "Ky-"), lyric(1, 0r, "Glo-"))
    expect(sung(upper_events[0r])).to eq [[1, "Ky", true], [2, "Glo", true]]
  end

  it "skips a standalone hyphen, the melisma marker, without spending a verse" do
    attach(lyric(1, 1/2r, "-"), lyric(1, 1/2r, " "), lyric(1, 1/2r, ""), lyric(1, 1/2r, "a"))
    expect(sung(upper_events[1/2r])).to eq [[1, "a", false]]
  end

  it "skips a lyric that falls on no onset" do
    attach(lyric(1, 3/4r, "lost"), lyric(2, 1/2r, "lost"), lyric(1, 1/2r, "ri"))
    events = upper_events.values + lower_events.values + alto_events.values
    expect(events.flat_map { |event| sung(event) }).to eq [[1, "ri", false]]
  end

  it "does not move a lyric with no onset in its own part to another part" do
    attach(lyric(2, 1/4r, "lost"), lyric(1, 1/4r, "ri"))
    expect(sung(lower_events[1/4r])).to eq [[1, "ri", false]]
  end

  it "sends a lyric from a track with no notes to the first part with an onset there" do
    attach(lyric(0, 0r, "Ky"), lyric(3, 1/4r, "ri"))
    expect([sung(upper_events[0r]), sung(lower_events[1/4r]), sung(alto_events[0r])]).to eq [[[1, "Ky", false]], [[1, "ri", false]], []]
  end

  it "keeps Latin accented and Cyrillic text exactly" do
    attach(lyric(1, 0r, "Glò-"), lyric(2, 0r, "Слава"))
    expect([sung(upper_events[0r]), sung(alto_events[0r])]).to eq [[[1, "Glò", true]], [[1, "Слава", false]]]
  end
end
